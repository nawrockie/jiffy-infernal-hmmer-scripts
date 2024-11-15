#!/usr/bin/env perl
# EPN, Mon Jan  6 11:44:52 2020
# ali-pfam-lowercase-rf-region.pl
#
# Given a pfam formatted alignment with RF annotation, and a region of
# RF positions, make all nucleotides within those regions lowercase.
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "ali-pfam-lowercase-rf-region.pl\n\n";
$usage .= "Usage:\n\n";
$usage .= "ali-pfam-lowercase-rf-region.pl <pfam formatted alignment file> <RF start position> <RF end position>\n";
#$usage .= "\tOPTIONS:\n";
#$usage .= "\t\t-s: additionally convert gap RF columns to '.' in individual SS and SS_cons lines [default: do not]\n\n";
#$usage .= "\t\t-o: *only* convert gap RF columns to '.' in individual SS and SS_cons lines, do not lowercase RF gap columns in each sequence\n\n";

#my $opt_s = 0; # set to '1' if -s used
#my $opt_o = 0; # set to '1' if -o used

#&GetOptions( "s"  => \$opt_s, 
#             "o"  => \$opt_o);

if(scalar(@ARGV) != 3) { die $usage; }

#if($opt_s && $opt_o) { die "ERROR only one of -s and -o can be used"; }

my ($aln_file, $rf_start, $rf_end) = (@ARGV);

if($rf_start <= 0) { die "ERROR <RF start position> must be >= 1"; }
if($rf_start > $rf_end) { die "ERROR <RF start position> must be <= <RF end position>"; }

my %seen_H = ();    # key is sequence name, used to check to make sure we are in Pfam format

open(IN, $aln_file) || die "ERROR unable to open $aln_file"; 

# first pass to determine rfgap columns
my $found_rf = 0;
my $i;
my @do_lowercase_A = (); # [0..alen], value is 1 if we should convert to lowercase because within rf_start..rf_end
my $line;

my $rfpos = 0;
while($line = <IN>) { 
  if($line =~ /^\#=GC\s+RF\s+(\S+)$/) { 
    if($found_rf) { 
      die "ERROR RF line found twice, did you convert to pfam format (e.g. esl-reformat pfam ...)?";
    }
    my $rf = $1;
    my @rf_A = split("", $rf);
    for($i = 0; $i < scalar(@rf_A); $i++) { 
      my $rf_is_gap = ($rf_A[$i] =~ m/[\.\-\_\~]/) ? 1 : 0; # RF gap characters are: '-', '.', '_' and '~'
      if(! $rf_is_gap) { $rfpos++; }
      $do_lowercase_A[$i] = (($rfpos >= $rf_start) && ($rfpos <= $rf_end)) ? 1 : 0;
    }
    $found_rf = 1;
  }
}
my $rflen = $rfpos;
if(! $found_rf) { die "ERROR did not find RF annotation"; }
close(IN);

if($rflen < $rf_start) { die "ERROR <RF start position> input as $rf_start but RF length is only $rflen"; }
if($rflen < $rf_end)   { die "ERROR <RF end position> input as $rf_end but RF length is only $rflen"; }

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
      if($do_lowercase_A[$i]) { 
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

