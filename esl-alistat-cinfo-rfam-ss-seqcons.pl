#!/usr/bin/env perl
# EPN, Tue Aug 29 19:01:47 2023
# esl-alistat-cinfo-rfam-ss-cons.pl
# Add the position conservation calculated in Bio-Easel's
# MSA.c:_c_pos_conservation (v0.16) to an esl-alistat
# --cinfo file. This is the conservation data that is
# colored on the Rfam (14.9) Secondary structure ->
# 'seqcons' page (rfam-family-pipeline/Rfam/Scripts/view/rfam_family_view.pl
# and rfam-family-pipeline/Rfam/Lib/Bio/Rfam/View/Plugin/SecondaryStructure.pm
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "perl esl-alistat-cinfo-rfam-ss-seqcons.pl [OPTIONS] <DNA or RNA alignment esl-alistat --cinfo output file>\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t--ignoregaps: report frequency of most common nt, ignoring gaps (default Rfam behavior: consider gaps)\n\n";

my $do_ignoregaps = 0;
&GetOptions( "ignoregaps" => \$do_ignoregaps);
             

if(scalar(@ARGV) != 1) { die $usage; }

my ($cinfo_file) = (@ARGV);
open(CINFO, $cinfo_file) || die "ERROR unable to open $cinfo_file";

## Per column residue counts:
## Alignment file: /Users/nawrockie/src/infernal-1.1.4/tutorial/Cobalamin.sto
## Alignment idx:  1
## Alignment name: Cobalamin
## Number of sequences: 431
## Ambiguities were averaged (e.g. 1 'N' = 0.25 'A', 0.25 'C', 0.25 'G' and 0.25 'U')
## Sequence weights from alignment were ignored (if they existed).
##
##  alnpos     A        C        G        U   
## -------  -------  -------  -------  -------
#        1    101.0    101.0     89.0    139.0
#        2    117.0    110.0     76.0    128.0

# The Rfam method counts gaps, so a gappy column cannot have high sequence conservation
# Here, gaps are not reported, but we can get number of sequences from line 4 so we
# don't need to know how many gaps.

my $nseq = undef;
while(my $line = <CINFO>) { 
  chomp $line;
  if($line =~ /^\# Number of sequences\:\s+(\d+)/) {
    $nseq = $1;
  }
  if(($line !~ m/^\#/) && ($line !~ m/^\/\/$/)) { 
    # data line
    chomp $line;
    my $orig_line = $line;
    $line =~ s/^\s+//;
    my @el_A = split(/\s+/, $line);
    if(scalar(@el_A) != 5) { die "ERROR expected 5 tokens on data line but got a different number: $line\n"; }
    my ($apos, $na, $nc, $ng, $nu) = (@el_A);
    if(! defined $nseq) {
      die "ERROR did not read number of sequences line before first data line";
    }
    #my $ngaps = ($nseq - ($na + $nc + $ng + $nu));
    my $max = $na;
    if($nc > $max) { $max = $nc; }
    if($ng > $max) { $max = $ng; }
    if($nu > $max) { $max = $nu; }
    
    my $denom = ($do_ignoregaps) ? ($na+$nc+$ng+$nu) : $nseq;
    my $seqcons = $max / $denom;

    printf("%s    %.3f\n", $orig_line, $seqcons);
  }
  elsif($line =~ m/alnpos/) {
    print("#  alnpos     A        C        G        U     maxfreq\n");
  }
  elsif($line =~ m/^\# ---/) { 
    print("# -------  -------  -------  -------  -------  -------\n");
  }
  else { 
    print $line . "\n";
  }
}
close(CINFO)
