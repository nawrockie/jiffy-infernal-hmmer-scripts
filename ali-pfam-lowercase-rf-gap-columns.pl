#!/usr/bin/env perl
# EPN, Mon Jan  6 11:44:52 2020
# ali-pfam-lowercase-rf-gap-columns.pl
#
# Given a pfam formatted alignment with RF annotation, convert any residues
# in sequences that are in RF-gap columns to lowercase.
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "ali-pfam-lowercase-rf-gap-columns.pl\n\n";
$usage .= "Usage:\n\n";
$usage .= "ali-pfam-lowercase-rf-gap-columns.pl <pfam formatted alignment file>\n";

#&GetOptions( "a"  => \$opt_a);

if(scalar(@ARGV) != 1) { die $usage; }

my ($aln_file) = (@ARGV);

my %seen_H      = ();    # key is sequence name, used to check to make sure we are in Pfam format

open(IN, $aln_file) || die "ERROR unable to open $aln_file"; 

# first pass to determine rfgap columns
my $found_rf = 0;
my $i;
my @rf_gap_A = ();
my $line;

while($line = <IN>) { 
  if($line =~ /^\#=GC\s+RF\s+(\S+)$/) { 
    if($found_rf) { 
      die "ERROR RF line found twice, did you convert to pfam format (e.g. esl-reformat pfam ...)?";
    }
    my $rf = $1;
    my @rf_A = split("", $rf);
    for($i = 0; $i < scalar(@rf_A); $i++) { 
      $rf_gap_A[$i] = ($rf_A[$i] =~ m/\w/) ? 0 : 1;
    }
    $found_rf = 1;
  }
}
if(! $found_rf) { die "ERROR did not find RF annotation"; }
close(IN);

# second pass to lowercase gap columns
open(IN, $aln_file) || die "ERROR unable to open $aln_file on second pass"; 
while($line = <IN>) { 
  chomp $line;
  if($line =~ /^(\S+)(\s+)(\S+)$/) { 
    my ($seqname, $space, $seq) = ($1, $2, $3);
    if((exists $seen_H{$seqname}) && ($seen_H{$seqname} == 1)) { 
      die "ERROR saw sequence $seqname twice, did you convert to pfam format (e.g. esl-reformat pfam ...)?";
    }
    $seen_H{$seqname} = 1;
    my @seq_A = split("", $seq);
    for($i = 0; $i < scalar(@seq_A); $i++) { 
      if($rf_gap_A[$i]) { 
        $seq_A[$i] =~ tr/A-Z/a-z/; 
      }
    }
    printf("%s%s%s\n", $seqname, $space, join("", @seq_A));
  }
  else { 
    print $line . "\n";
  }
}
close(IN);

