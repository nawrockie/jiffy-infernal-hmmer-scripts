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
$usage  = "ali-pfam-fragmentize.pl\n\n";
$usage .= "Usage:\n\n";
$usage .= "ali-pfam-fragmentize.pl <pfam formatted alignment file>\n";
#$usage .= "\tOPTIONS:\n";
#$usage .= "\t\t-s: additionally convert gap RF columns to '.' in individual SS and SS_cons lines [default: do not]\n\n";
#$usage .= "\t\t-o: *only* convert gap RF columns to '.' in individual SS and SS_cons lines, do not lowercase RF gap columns in each sequence\n\n";

#my $opt_s = 0; # set to '1' if -s used
#my $opt_o = 0; # set to '1' if -o used

#&GetOptions( "s"  => \$opt_s, 
#             "o"  => \$opt_o);

if(scalar(@ARGV) != 1) { die $usage; }

my ($aln_file) = (@ARGV);

open(IN, $aln_file) || die "ERROR unable to open $aln_file"; 
while(my $line = <IN>) { 
  chomp $line;
  if($line =~ /^(\S+)(\s+)(\S+)$/) { 
    my ($seqname, $space, $seq) = ($1, $2, $3);
    my @seq_A =  split("", $seq);
    my $seqlen = scalar(@seq_A);
    my $i = 0;
    while($i < $seqlen) {
      if(($seq_A[$i] eq "-") || ($seq_A[$i] eq ".")) {
        $seq_A[$i] = "~";
      }
      elsif($seq_A[$i] ne "~") {
        $i = $seqlen;
      }
      $i++;
    }
    $i = $seqlen-1;
    while($i > 0) {
      if(($seq_A[$i] eq "-") || ($seq_A[$i] eq ".")) {
        $seq_A[$i] = "~";
      }
      elsif($seq_A[$i] ne "~") {
        $i = 0;
      }
      $i--;
    }
    my $newseq = join("", @seq_A);
    printf("%s%s%s\n", $seqname, $space, $newseq);
  }
  else {
      print $line . "\n";
  }
}
close(IN);

