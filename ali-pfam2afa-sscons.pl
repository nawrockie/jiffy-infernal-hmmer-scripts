#!/usr/bin/env perl
# EPN, Fri Nov 15 13:30:45 2019
# ali-pfam2afa-ssoncs.pl
#
# Given a pfam formatted alignment with consensus structure annotation (#=GC SS_cons)
# convert it to aligned fasta with dot-bracket notation.
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "ali-pfam2afa-sscons.pl\n\n";
$usage .= "Usage:\n\n";
$usage .= "Pfam (1 line Stockholm) formatted alignment to aligned FASTA:\n";
$usage .= "ali-pfam2afa-sscons.pl [OPTIONS] <alignment file in Pfam format with SS_cons annotation>\n\n";
$usage .= "Stockholm formatted alignment to aligned FASTA:\n";
$usage .= "esl-reformat pfam <stockholm alignment> | ali-pfam2afa-sscons.pl [OPTIONS] -\n\n";

my $do_upper      = 0;
my $do_dotbracket = 0;
my %seen_H = ();

&GetOptions( "upper"      => \$do_upper,
             "dotbracket" => \$do_dotbracket);

if(scalar(@ARGV) != 1) { die $usage; }
my ($aln_file) = (@ARGV);

open(IN, $aln_file) || die "ERROR unable to open $aln_file"; 

my %desc_H = ();
while(my $line = <>) { 
  if($line =~ m/^\#=GS\s+(\S+)\s+DE\s+(.+)$/) { 
    $desc_H{$1} = $2;
  }
  elsif($line !~ /^\#/) { 
    if($line =~ /^(\S+)\s+(\S+)/) { 
      my ($seqname, $seq) = ($1, $2);
      if($seen_H{$seqname}) { die "ERROR, alignment looks interleaved, saw $seqname twice. Reformat to pfam with 'esl-reformat pfam <input.sto>'\n"; }
      print(">$seqname");
      if(defined $desc_H{$seqname}) {
        print(" $desc_H{$seqname}");
      }
      print("\n");
      if($do_dotbracket) { 
        $seq =~ s/[^A-Z]/./g;
      }
      if($do_upper) {
        $seq =~ tr/a-z/A-Z/;
      }        
      print $seq . "\n";
    }
  }
  elsif($line =~ /^\#=GC\s+SS\_cons\s+(\S+)/) { 
    my ($orig_ss) = $1;
    my $ss = $orig_ss;
    if($do_dotbracket) { 
      $ss =~ s/[\{\[\<\(]/\(/g;
      $ss =~ s/[\}\]\>\)]/\)/g;
      $ss =~ s/[\:\_\,\-\~]/\./g;
    }
    print(">SS_cons\n$ss\n");
  }
}
close(IN);
