#!/usr/bin/env perl
# 
# fasta-description-preprend.pl: prepend a string to the description of all sequences in a fasta file
#                        
use strict;
use warnings;
use Getopt::Long;

my $usage = "perl fasta-description-prepend.pl <fasta file> <string to prepend>\n";

if(scalar(@ARGV) != 2) { die $usage; }
my ($fa_file, $desc2add) = (@ARGV);

open(IN, $fa_file) || die "ERROR unable to open $fa_file for reading"; 

while(my $line = <IN>) { 
  chomp $line;
  if($line =~ /^\>(\S+)\s+(.*)$/) { 
    printf(">%s %s %s\n", $1, $desc2add, $2);
  }
  else {
    print $line . "\n";
  }
}
close(IN);


