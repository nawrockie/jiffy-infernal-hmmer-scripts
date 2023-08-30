#!/usr/bin/env perl
# EPN, Wed Sep 16 12:00:25 2020
# ali-pfam-add-sscons.pl
#
# Given a pfam formatted alignment with RF annotation, rewrite the RF annotation 
# to make all positions RF gaps except: 
# - structured positions
# - positions that are part of N or more consecutive capitalized single stranded RF positions 
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "ali-pfam-add-structonly-rf.pl\n\n";
$usage .= "Usage:\n\n";
$usage .= "perl ali-pfam-add-structonly-rf.pl\n\t";
$usage .= "<pfam formatted alignment file to rewrite RF for>\n\t";
$usage .= "<N: number of consecutive single stranded positions that must be capitalized to keep as nongap in RF, -1 for ONLY structure>\n\t";
$usage .= "<'Y' or 'N' for whether contiguous capitalized RF positions adjacent to structured positions should be kept as nongap>\n\n";


if(scalar(@ARGV) != 3) { die $usage; }

my ($alifile, $N, $do_adj) = (@ARGV);

if($do_adj eq "Y") { 
  $do_adj = 1;
}
elsif($do_adj eq "N") { 
  $do_adj = 0;
} 
else { 
  die "ERROR, 3rd argument should be Y or N";
}

if(($do_adj) && ($N == -1)) { 
  die "ERROR N value of -1 is incompatible with 3rd arg of Y";
}

my %seen_H = ();    # key is sequence name, used to check to make sure we are in Pfam format

open(ALI, $alifile) || die "ERROR unable to open $alifile"; 
# first pass to determine rf_nongap columns
my $found_rf = 0;
my $i;
my @rf_nongap_A = ();
my $line;
my $rflen = 0;
my $rfspacelen = 0; # length of space between "RF" and start of RF annotation in "#=GC RF   ..." line
my $alen = 0;
my $seen_sscons = 0;

my @sscons_A = ();

my @keepme_A = ();
my $ncaprun = 0; # number of consecutive capitalized values in RF currently seen

my @rf_A = ();

while($line = <ALI>) { 
  if($line =~ /^\#=GC\s+SS_cons(\s+)(\S+)$/) { 
    $seen_sscons = 1;
    my $sscons = $2;
    @sscons_A = split("", $sscons);
  }

  if($line =~ /^\#=GC\s+RF(\s+)(\S+)$/) { 
    if(! $seen_sscons) { 
      die "ERROR did not read SS_cons line before RF line"; 
    }
    $rfspacelen = length($1);
    my $rf = $2;
    @rf_A = split("", $rf);
    $alen = scalar(@rf_A);

    if($found_rf) { 
      die "ERROR RF line found twice, did you convert to pfam format (e.g. esl-reformat pfam ...)?";
    }
    for($i = 0; $i < scalar(@rf_A); $i++) { 
      if($rf_A[$i] eq ".") { 
        $keepme_A[$i] = 1; # will stay a gap
        $ncaprun = 0;
      }
      else { 
        if($rf_A[$i] =~ m/[A-Z]/) { 
          $ncaprun++;
        }
        else { 
          $ncaprun = 0;
        }
        if($sscons_A[$i] =~ m/[\<\{\(\[\>\}\)\]]/) { 
          # basepair, keep
          $keepme_A[$i] = 1;

          if(($do_adj) && ($N != -1)) { 
            $ncaprun = $N; # this makes it so any contiguous capitalized positions 3' of a structured positions are kept

            # also keep consecutive positions 5' of this position that are capitalized
            my $i2 = $i-1;
            while(($i2 > 0) && ($sscons_A[$i2] !~ m/[\<\{\(\[\>\}\)\]]/) && ($rf_A[$i2] =~ m/[A-Z]/)) { 
              $keepme_A[$i2] = 1;
              $i2--;
            }
          }
        }
        elsif(($N != -1) && ($ncaprun >= $N)) { 
          for(my $i2 = ($i-$ncaprun+1); $i2 <= $i; $i2++) { 
            $keepme_A[$i2] = 1;
          }
        }
        else { 
          # unstructured, and minimum length not met
          $keepme_A[$i] = 0;
        }
      }
    }
    $found_rf = 1;
    # print NEW rf and original RF
    my $new_rf = "";
    if((scalar(@keepme_A)) != (scalar(@rf_A))) { 
      die "ERROR diff lengths keepme_A and rf_A\n";
    }
    for(my $i = 0; $i < scalar(@keepme_A); $i++) { 
      if($keepme_A[$i]) { 
        $new_rf .= $rf_A[$i];
      }
      else { 
        $new_rf .= ".";
      }
    }
    my $new_spacer = "";
    my $old_spacer = "";
    for(my $i = 0; $i < $rfspacelen; $i++) { 
      $new_spacer .= " ";
    }
    for(my $i = 0; $i < ($rfspacelen-5); $i++) { 
      $old_spacer .= " ";
    }
    printf("#=GC RF%s%s\n",      $new_spacer, $new_rf);
    printf("#=GC RF_orig%s%s\n", $old_spacer, $rf);
  }
  elsif($line =~ /^(\S+)(\s+)(\S+)$/) { 
    my ($seqname, $space, $seq) = ($1, $2, $3);
    if((exists $seen_H{$seqname}) && ($seen_H{$seqname} == 1)) { 
      die "ERROR saw sequence $seqname twice, did you convert to pfam format (e.g. esl-reformat pfam ...)?";
    }
    $seen_H{$seqname} = 1;
    print $line;
  }
  else { 
    print $line; 
  }
}
close(ALI);

