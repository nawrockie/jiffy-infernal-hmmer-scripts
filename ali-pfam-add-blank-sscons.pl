#!/usr/bin/env perl
# EPN, Wed Nov 20 13:34:13 2019
# ali-pfam-add-blank-sscons.pl
#
# Given a pfam formatted alignment without consensus structure annotation (#=GC SS_cons)
# add #=GC SS_cons annotation with zero basepairs (all dots '.'s)
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "ali-pfam-add-blank-sscons.pl\n\n";
$usage .= "Usage:\n\n";
$usage .= "Add blank SS_cons to Pfam (1 line Stockholm) formatted alignment:\n";
$usage .= "ali-pfam-add-blank-sscons.pl <alignment file in Pfam format with SS_cons annotation>\n\n";
$usage .= "Stockholm formatted alignment to aligned FASTA:\n";
$usage .= "esl-reformat pfam <stockholm alignment> | ali-pfam-add-blank-sscons.pl -\n\n";

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
      my $ss_line = ""; 
      for(my $i = 0; $i < $alilen; $i++) { $ss_line .= "."; }
      print "#=GC SS_cons $ss_line\n";
    }
  }
  print $line . "\n";
}
