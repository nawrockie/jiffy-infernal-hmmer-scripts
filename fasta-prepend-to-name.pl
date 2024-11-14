#!/usr/bin/env perl
# 
# fasta-prepend-to-name.pl: prepend a string to the beginning of sequence names
#                        
use strict;
use warnings;
use Getopt::Long;

my $usage = "perl fasta-remove-dups.pl <fasta file> <string to prepend to seqnames>\n";

if(scalar(@ARGV) != 2) { die $usage; }

my ($fasta_file, $prestr) = (@ARGV);

open(IN, $fasta_file) || die "ERROR unable to open $fasta_file for reading";
while(my $line = <IN>) { 
  if($line =~ /^\>(\S+)/) { 
    my $seqname = $1;
    print(">" . $prestr . $seqname . "\n");
  }
  else {
    print $line;
  }
}
close(IN);
