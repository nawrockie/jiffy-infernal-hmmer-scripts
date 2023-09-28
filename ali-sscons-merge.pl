#!/usr/bin/env perl
# EPN, Tue Sep 26 15:09:31 2023
# ali-sscons-merge.pl
#
# Merge the SS_cons line from two pfam-formatted alignments and output the first alignment
# with the merged SS_cons line. This script is RF-agnostic, because it can be used to 
# merge SS_cons lines from alignments from different CMs, for example. It does check that
# the length of the two alignments are *identical* (following possible consideration of the 
# --one_m5, --one_m3, --two_m5, --two_m3 options), and dies if they are not.
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "perl ali-sscons-merge.pl [OPTIONS] <pfam-formatted alignment file 1> <pfam-formatted alignment file 2>\n\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t--one_m5 <n>: alignment 1 is missing <n> positions at the 5' end\n";
$usage .= "\t\t--one_m3 <n>: alignment 1 is missing <n> positions at the 3' end\n";
$usage .= "\t\t--two_m5 <n>: alignment 2 is missing <n> positions at the 5' end\n";
$usage .= "\t\t--two_m3 <n>: alignment 2 is missing <n> positions at the 3' end\n";

my $one_m5 = 0; # set to <n> from --onem5 <n> if used
my $one_m3 = 0; # set to <n> from --onem3 <n> if used
my $two_m5 = 0; # set to <n> from --twom5 <n> if used
my $two_m3 = 0; # set to <n> from --twom3 <n> if used

&GetOptions( "one_m5=s" => \$one_m5, 
             "one_m3=s" => \$one_m3, 
             "two_m5=s" => \$two_m5, 
             "two_m3=s" => \$two_m3);

if(scalar(@ARGV) != 2) { die $usage; }

my ($aln_file1, $aln_file2) = (@ARGV);

my $i;
my $one_m5_str = "";
my $one_m3_str = "";
my $two_m5_str = "";
my $two_m3_str = "";
for($i = 0; $i < $one_m5; $i++) { $one_m5_str .= "."; }
for($i = 0; $i < $one_m3; $i++) { $one_m3_str .= "."; }
for($i = 0; $i < $two_m5; $i++) { $two_m5_str .= "."; }
for($i = 0; $i < $two_m3; $i++) { $two_m3_str .= "."; }

my $found_sscons = 0;
my $sscons1      = undef;
my $sscons2      = undef;
my @sscons1_A    = ();
my @sscons2_A    = ();
my @seq1_A       = ();
my @seqname1_A   = ();
my $seqname1_w   = length("#=GC SS_cons");
my $line         = undef;
my $seqname      = undef;
my $seq          = undef;

open(IN, $aln_file1) || die "ERROR unable to open $aln_file1"; 
while($line = <IN>) { 
  chomp $line;
  if(($line !~ /^\#/) && ($line !~ m/\/\//) && ($line =~ m/\w/)) { 
    # sequence line
    if($line =~ /^(\S+)\s+(\S+)/) { 
      ($seqname, $seq) = ($1, $2);
      if(length($seqname) > $seqname1_w) { $seqname1_w = length($seqname); }
      push(@seqname1_A, $seqname);
      push(@seq1_A, ($one_m5_str . $seq . $one_m3_str));
    }
    else { 
      die "ERROR unable to parse sequence name out of alignment 1 seq line: $line\n";
    }
  }
  if($line =~ /^\#=GC\s+SS\_cons\s+(\S+)$/) { 
    my $sscons = $1;
    if($found_sscons) { 
      die "ERROR found SS_cons twice in $aln_file1, did you convert to pfam format (e.g. esl-reformat pfam ...)?";
    }
    $sscons1 = $one_m5_str . $sscons . $one_m3_str;
    @sscons1_A = split("", $sscons1);
    $found_sscons = 1;
  }
}
if(! $found_sscons) { die "ERROR did not find SS_cons annotation in $aln_file1"; }
close(IN);

$found_sscons = 0;
open(IN, $aln_file2) || die "ERROR unable to open $aln_file2"; 
while($line = <IN>) { 
  chomp $line;
  # we don't care about the sequence data in alignment 2
  if($line =~ /^\#=GC\s+SS\_cons\s+(\S+)$/) { 
    if($found_sscons) { 
      die "ERROR found SS_cons twice in $aln_file2, did you convert to pfam format (e.g. esl-reformat pfam ...)?";
    }
    $sscons2 = $two_m5_str . $1 . $two_m3_str;
    @sscons2_A = split("", $sscons2);
    $found_sscons = 1;
  }
}
if(! $found_sscons) { die "ERROR did not find SS_cons annotation in $aln_file1"; }
close(IN);

if((scalar(@sscons1_A)) != (scalar(@sscons2_A))) { 
  my $err_str = "ERROR, alignments are not the same length (after accounting for --{one,two}_m{5,3} options).\n";
  $err_str .= sprintf("Alignment 1: %d (--one_m5) + %d (input aln length) + %d (--one_m3) = %d\n", $one_m5, (length($sscons1) - $one_m5 - $one_m3), $one_m3, length($sscons1));
  $err_str .= sprintf("Alignment 2: %d (--two_m5) + %d (input aln length) + %d (--two_m3) = %d\n", $two_m5, (length($sscons2) - $two_m5 - $two_m3), $two_m3, length($sscons2));
  die $err_str;
}

# build the merged SS_cons
# make sure that we don't have any SS annotation that conflicts
# if either alignment has a bp in a position then the other alignment *must* have no structure there
my $merged_sscons = "";
my $length = scalar(@sscons1_A);
for($i = 0; $i < $length; $i++) { 
  my $bp1 = (($sscons1_A[$i] =~ m/[\(\<\{\[\)\>\}\]]/) || ($sscons1_A[$i] =~ m/[A-Za-z]/)) ? 1 : 0;
  my $bp2 = (($sscons2_A[$i] =~ m/[\(\<\{\[\)\>\}\]]/) || ($sscons2_A[$i] =~ m/[A-Za-z]/)) ? 1 : 0;
  if($bp1 && $bp2) { 
    my $err_str = sprintf("ERROR, the two alignments both have structure at position %d: '%s' in aln 1 and '%s' in aln 2.\n", ($i+1), $sscons1_A[$i], $sscons2_A[$i]);
    $err_str .= "This script requires that any structured position in one of the alignments\n";
    $err_str .= "be unstructured in the other alignment.\n";
    die $err_str;
  }

  # add the character from whichever aln has structure, if neither are, default to adding alignment 1's character
  $merged_sscons .= ($bp2) ? $sscons2_A[$i] : $sscons1_A[$i]; 
}
 
# output 
print "# STOCKHOLM 1.0\n\n";
for($i = 0; $i < scalar(@seq1_A); $i++) { 
  printf("%-*s " . $seq1_A[$i] . "\n", $seqname1_w, $seqname1_A[$i]);
}
printf("%-*s $merged_sscons\n", $seqname1_w, "#=GC SS_cons");
print("//\n");

