# EPN, Tue May 22 11:46:21 2018
# esl-alistat-cinfo-count-mutations.pl
# Summarize an esl-alistat --cinfo DNA or RNA alignment file.
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "perl esl-alistat-cinfo-count-mutations.pl [OPTIONS] <DNA or RNA alignment esl-alistat --cinfo output file>\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t--bpinfo <s>: name of bpinfo file to use to define single stranded vs paired positions\n";
$usage .= "\t\t--frame:      break down number of changes by frame (for DNA alignments of protein coding regions)\n";
$usage .= "\t\t              (w/--frame you may want to remove all insert columns first, e.g. 'esl-alimask --rf-is-mask')\n\n";

my $do_frame = 0;
my $bpinfo_file = undef;
&GetOptions( "bpinfo=s" => \$bpinfo_file,
             "frame"    => \$do_frame); 
             

if(scalar(@ARGV) != 1) { die $usage; }

if($do_frame && (defined $bpinfo_file)) { 
  die "ERROR can't use both --frame and --bpinfo files, pick one.";
}

my ($cinfo_file) = (@ARGV);
open(CINFO, $cinfo_file) || die "ERROR unable to open $cinfo_file";

my %is_paired_H = ();
my $have_pairs = 0;
my $line;
if(defined $bpinfo_file) { 
  $have_pairs = 1;
  open(BPINFO, $bpinfo_file) || die "ERROR unable to open $bpinfo_file for reading";

  while($line = <BPINFO>) { 
    chomp $line;
    if(($line !~ m/^\/\/$/) && ($line !~ m/^\#/)) { 
      $line =~ s/^\s+//;
      $line =~ s/\s+$//;
      my @el_A = split(/\s+/, $line);
      if(scalar(@el_A) != 18) { die "ERROR expected 18 tokens on data line but got a different number: $line\n"; }
      my ($lpos, $rpos) = ($el_A[0], $el_A[1]);
      $is_paired_H{$lpos} = 1;
      $is_paired_H{$rpos} = 1;
    }
  }
  close(BPINFO);
}

#######
# Beginning of cinfo file
## Per column residue counts:
## Alignment file: syn-s2.refined.pgo1a-plus2.supported.cmbuild.stk
## Alignment idx:  1
## Alignment name: syn-s2.pgo1a-plus2.supported
## Number of sequences: 19
## Ambiguities were averaged (e.g. 1 'N' = 0.25 'A', 0.25 'C', 0.25 'G' and 0.25 'U')
## Sequence weights from alignment were ignored (if they existed).
##
##  alnpos     A        C        G        U   
## -------  -------  -------  -------  -------
#        1      0.0      1.0     18.0      0.0
#        2      0.0      1.0      1.0     17.0

my $tot_nmaj_paired    = 0;
my $tot_ndiff_paired   = 0;
my $tot_nmaj_unpaired  = 0;
my $tot_ndiff_unpaired = 0;
my %tot_nmaj_unpaired_by_frame_H  = ();
my %tot_ndiff_unpaired_by_frame_H = ();
my $nmaj = 0;
my $ndiff = 0;
while($line = <CINFO>) { 
  chomp $line;
  if(($line !~ m/^\#/) && ($line !~ m/^\/\/$/)) { 
    # data line
    chomp $line;
    $line =~ s/^\s+//;
    my @el_A = split(/\s+/, $line);
    if(scalar(@el_A) != 5) { die "ERROR expected 5 tokens on data line but got a different number: $line\n"; }
    my ($apos, $na, $nc, $ng, $nu) = (@el_A);
    my $frame = (($apos-1) % 3) + 1; # 1 -> 1; 2 -> 2; 3 -> 3; 4 -> 1, etc.

    if(($na >= $nc) && 
       ($na >= $ng) && 
       ($na >= $nu)) { 
      # a is most common:
      $nmaj  = $na;
      $ndiff = $nc + $ng + $nu;
    }
    elsif(($nc >= $na) && 
          ($nc >= $ng) && 
          ($nc >= $nu)) { 
      # c is most common:
      $nmaj  = $nc;
      $ndiff = $na + $ng + $nu;
    }
    elsif(($ng >= $na) && 
          ($ng >= $nc) && 
          ($ng >= $nu)) { 
      # g is most common:
      $nmaj  = $ng;
      $ndiff = $na + $nc + $nu;
    }
    elsif(($nu >= $na) && 
          ($nu >= $nc) && 
          ($nu >= $ng)) { 
      # u is most common:
      $nmaj  = $nu;
      $ndiff = $na + $nc + $ng;
    }
    else { 
      die "ERROR coudn't determine dominant nt in line: $line";
    }
    if(exists $is_paired_H{$apos}) { 
      $tot_nmaj_paired  += $nmaj;
      $tot_ndiff_paired += $ndiff;
    }
    else { 
      $tot_nmaj_unpaired  += $nmaj;
      $tot_ndiff_unpaired += $ndiff;
      $tot_nmaj_unpaired_by_frame_H{$frame}  += $nmaj;
      $tot_ndiff_unpaired_by_frame_H{$frame} += $ndiff;
      # only need by_frame updates for unpaired because --frame and --bpinfo are incompatible options
    }
  }
}

if($have_pairs) { 
  printf("Number of   most common nucleotide in   paired columns: %5d  [%5.3f]\n", $tot_nmaj_paired, $tot_nmaj_paired / ($tot_nmaj_paired + $tot_ndiff_paired));
  printf("Number of ! most common nucleotide in   paired columns: %5d  [%5.3f]\n", $tot_ndiff_paired, $tot_ndiff_paired / ($tot_nmaj_paired + $tot_ndiff_paired));
  printf("Number of   most common nucleotide in unpaired columns: %5d  [%5.3f]\n", $tot_nmaj_unpaired, $tot_nmaj_unpaired / ($tot_nmaj_unpaired + $tot_ndiff_unpaired));
  printf("Number of ! most common nucleotide in unpaired columns: %5d  [%5.3f]\n", $tot_ndiff_unpaired, $tot_ndiff_unpaired / ($tot_nmaj_unpaired + $tot_ndiff_unpaired));
}
else { 
  if($do_frame) { 
    foreach my $frame ("1", "2", "3") { 
      printf("Number of   most common nucleotide in all frame $frame columns: %5d  [%5.3f]\n", $tot_nmaj_unpaired_by_frame_H{$frame}, $tot_nmaj_unpaired_by_frame_H{$frame}   / ($tot_nmaj_unpaired_by_frame_H{$frame} + $tot_ndiff_unpaired_by_frame_H{$frame}));
      printf("Number of ! most common nucleotide in all frame $frame columns: %5d  [%5.3f]\n", $tot_ndiff_unpaired_by_frame_H{$frame}, $tot_ndiff_unpaired_by_frame_H{$frame} / ($tot_nmaj_unpaired_by_frame_H{$frame} + $tot_ndiff_unpaired_by_frame_H{$frame}));
    }
  }
  else { # ! $do_frame
    printf("Number of   most common nucleotide in all columns: %5d  [%5.3f]\n", $tot_nmaj_unpaired, $tot_nmaj_unpaired / ($tot_nmaj_unpaired + $tot_ndiff_unpaired));
    printf("Number of ! most common nucleotide in all columns: %5d  [%5.3f]\n", $tot_ndiff_unpaired, $tot_ndiff_unpaired / ($tot_nmaj_unpaired + $tot_ndiff_unpaired));
  }
}

