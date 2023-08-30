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
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t-s: additionally convert gap RF columns to '.' in individual SS and SS_cons lines [default: do not]\n\n";
$usage .= "\t\t-o: *only* convert gap RF columns to '.' in individual SS and SS_cons lines, do not lowercase RF gap columns in each sequence\n\n";

my $opt_s = 0; # set to '1' if -s used
my $opt_o = 0; # set to '1' if -o used

&GetOptions( "s"  => \$opt_s, 
             "o"  => \$opt_o);

if(scalar(@ARGV) != 1) { die $usage; }

if($opt_s && $opt_o) { die "ERROR only one of -s and -o can be used"; }

my ($aln_file) = (@ARGV);

my %seen_H = ();    # key is sequence name, used to check to make sure we are in Pfam format

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
      $rf_gap_A[$i] = ($rf_A[$i] =~ m/[\.\-\_\~]/) ? 1 : 0; # RF gap characters are: '-', '.', '_' and '~'
    }
    $found_rf = 1;
  }
}
if(! $found_rf) { die "ERROR did not find RF annotation"; }
close(IN);

# second pass to lowercase RF gap columns in sequences and optionally convert RF gap columns in individual SS and SS_cons lines to '.'
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
        $seq_A[$i] =~ tr/\-/\./; # convert - to .
      }
    }
    if(! $opt_o) { 
      printf("%s%s%s\n", $seqname, $space, join("", @seq_A));
    }
    else { # don't modify seq
      printf("%s%s%s\n", $seqname, $space, $seq);
    }
  }
  elsif($opt_s || $opt_o) { 
    if($line =~ /^(\#=GR\s+)(\S+)(\s+SS\s+)(\S+)$/) { 
      my ($gr, $seqname, $ss_and_space, $ss) = ($1, $2, $3, $4);
      my @ss_A = split("", $ss);
      for($i = 0; $i < scalar(@ss_A); $i++) { 
        if($rf_gap_A[$i]) { 
          $ss_A[$i] = ".";
        }
      }
      printf("%s%s%s%s\n", $gr, $seqname, $ss_and_space, join("", @ss_A));
    }
    elsif($line =~ /^(\#=GC\s+SS\_cons\s+)(\S+)$/) { 
      my ($gc_sscons_and_space, $ss) = ($1, $2);
      my @ss_A = split("", $ss);
      for($i = 0; $i < scalar(@ss_A); $i++) { 
        if($rf_gap_A[$i]) { 
          $ss_A[$i] = ".";
        }
      }
      printf("%s%s\n", $gc_sscons_and_space, join("", @ss_A));
    }
    else { 
      print $line . "\n";
    }
  } # end of 'elsif($opt_s)'
  else { 
    print $line . "\n";
  }
}
close(IN);

