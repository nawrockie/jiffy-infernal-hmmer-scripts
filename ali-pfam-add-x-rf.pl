#!/usr/bin/env perl
# EPN, Tue Sep 26 18:05:59 2023
# ali-pfam-add-x-rf.pl
#
# Given a pfam formatted alignment without RF annotation (#=GC RF)
# add #=GC RF annotation with every position in the RF annotation 
# set as 'x'.
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "ali-pfam-add-x-rf.pl\n\n";
$usage .= "Usage:\n\n";
$usage .= "Add RF of all 'x' to Pfam (1 line Stockholm) formatted alignment:\n";
$usage .= "ali-pfam-add-x-rf.pl <alignment file in Pfam format without RF annotation>\n\n";

my %seen_H = ();
my $alilen = -1;

if(scalar(@ARGV) != 1) { die $usage; }

while(my $line = <>) { 
  chomp $line;
  if($line !~ /^\#/) { 
    if($line =~ /^(\S+)\s+(\S+)/) { 
      my ($seqname, $seq) = ($1, $2);
      if($seen_H{$seqname}) { die "ERROR, alignment looks interleaved, saw $seqname twice. Reformat to pfam with 'esl-reformat pfam <input.sto>'\n"; }
      my $len = length($seq);
      if(($alilen != -1) && ($alilen != $len)) { die "ERROR read different length aligned seqs, one of length $alilen, but then the following aligned seq len
gth is $len:$seq\n"; }
      $alilen = $len;
    }
    if($line =~ /^\/\/$/) { 
      my $rf_line = "";
      for(my $i = 0; $i < $alilen; $i++) { $rf_line .= "x"; }
      print "#=GC RF $rf_line\n";
    }
  }
  elsif($line =~ m/^\#=GC RF/) { 
    die "ERROR alignment already has RF annotation";
  }
  print $line . "\n";
}
