#!/usr/bin/env perl
# EPN, Mon Dec  2 11:24:10 2024
#
# Given a pfam formatted alignment with existing RF annotation, change the
# RF annotation to a sequence with the name given as input.
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "ali-pfam-rename-rf.pl\n\n";
$usage .= "Usage:\n\n";
$usage .= "perl ali-pfam-rename-rf.pl\n\t";
$usage .= "<pfam formatted alignment file with RF annotation to rename>\n\t";
$usage .= "<sequence name to use for existing RF>\n\n";

#&GetOptions( "a"  => \$opt_a);

if(scalar(@ARGV) != 2) { die $usage; }

my ($alifile, $rf_seqname) = (@ARGV);

my %seen_H = ();  # key is sequence name, used to check to make sure we are in Pfam format

open(ALI, $alifile) || die "ERROR unable to open $alifile"; 
# first pass to determine rf_nongap columns
my $found_rf = 0;
my $line;
while($line = <ALI>) { 
  if($line =~ /(^\#=GC\s+RF\s+)(\S+)$/) { 
    $found_rf = 1;
    my $namelen = length($1);
    my $rf = $2;
    printf("%-*s %s\n", ($namelen-1), $rf_seqname, $rf);
  }
  else {
    print $line;
    if($line =~ /^(\S+)\s+(\S+)$/) { 
      my ($seqname, $seq) = ($1, $2);
      if((exists $seen_H{$seqname}) && ($seen_H{$seqname} == 1)) { 
        die "ERROR saw sequence $seqname twice, did you convert to pfam format (e.g. esl-reformat pfam ...)?";
      }
      $seen_H{$seqname} = 1;
    }
  }
}
if(! $found_rf) { die "ERROR did not find RF annotation in $alifile"; }
close(ALI);


