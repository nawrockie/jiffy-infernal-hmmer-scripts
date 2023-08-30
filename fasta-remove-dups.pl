#!/usr/bin/env perl
# 
# fasta-remove_dup_seqnames.pl: remove any seqs that have the same name as another
#                        
use strict;
use warnings;
use Getopt::Long;

my $usage = "perl fasta-remove-dups.pl <fasta file>\n";

my %seen_H = ();
my $print_flag = 1;

while(my $line = <>) { 
  if($line =~ /^\>(\S+)/) { 
    my $seqname = $1;
    if(! defined $seen_H{$seqname}) { 
      $seen_H{$seqname} = 1;
      $print_flag = 1;
    }
    else { 
      $print_flag = 0;
    }
  }
  if($print_flag) { print $line; }
}
