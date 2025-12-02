#!/usr/bin/env perl
# EPN, Sat Oct 25 13:46:11 2025
# ali-pfam-add-rfseqs-with-insert.pl
#
# Given a pfam formatted alignment with RF annotation, add new sequence(s)
# that are the RF sequence with an insert of length <n> after nongap RF
# position <c>
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "ali-pfam-add-rfseqs-with-insert.pl\n\n";
$usage .= "Usage:\n\n";
$usage .= "ali-pfam-add-rfseq-with-insert.pl\n\t<pfam formatted alignment file>\n\t<nongap RF position to add insert after>\n\t<length of insert to add>\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t-n <n>: add <n> > 1 copies of the new sequence";

my $opt_n = 1; # set to <n> if -n <n> used

&GetOptions( "n=s" => \$opt_n);

if(scalar(@ARGV) != 3) { die $usage; }

if($opt_n != 1) {
  if($opt_n !~ m/^\d+$/) {
    die "ERROR with -n <n>, <n> should be a positive integer >= 2";
  }
}
  
my ($aln_file, $ins_rfpos, $ins_length) = (@ARGV);

# create insert to add for new rfseq and gap region to add for all other seqs
my $i;
my $ins_to_add = "";
my $gap_to_add = "";
for($i = 0; $i < $ins_length; $i++) { 
  $ins_to_add .= "n";
  $gap_to_add .= ".";
}

my $rfseq_to_add_name = "RF." . "ins" . $ins_length . ".pos" . $ins_rfpos;
my $rfseq_to_add_name_length = length($rfseq_to_add_name);

# first pass to determine rfgap columns
my $found_rf = 0;
my $found_rfpos = 0;
my $line;
my $rfpos = 0;
my $posn_for_insert = -1;
my $rfseq_to_add = "";
my $final_seqname = "";
open(IN, $aln_file) || die "ERROR unable to open $aln_file"; 
while($line = <IN>) { 
  if(($line !~ /^\#/) && ($line =~ /^(\S+)\s+\S+$/)) {
    $final_seqname = $1; # keep track of final seq name, so we know when to output $rfseq_to_add
  }
  if($line =~ /^\#=GC\s+RF\s+(\S+)$/) { 
    if($found_rf) { 
      die "ERROR RF line found twice, did you convert to pfam format (e.g. esl-reformat pfam ...)?";
    }
    my $rf = $1;
    my @rf_A = split("", $rf);
    for($i = 0; $i < scalar(@rf_A); $i++) { 
      my $rf_is_gap = ($rf_A[$i] =~ m/[\.\-\_\~]/) ? 1 : 0; # RF gap characters are: '-', '.', '_' and '~'
      if(! $rf_is_gap) {
        if($rfpos == $ins_rfpos) {
          $posn_for_insert = $i;
          $rfseq_to_add .= $ins_to_add;
          $found_rfpos = 1;
        }
        $rfpos++;
      }
      $rfseq_to_add .= $rf_A[$i];
    }
    $found_rf = 1;
  }
}
my $rflen = $rfpos;
if(! $found_rf)    { die "ERROR did not find RF annotation"; }
if(! $found_rfpos) { die "ERROR found RF annotation but nongap length was shorter than $ins_rfpos positions"; }
close(IN);

# second pass - output 
open(IN, $aln_file) || die "ERROR unable to open $aln_file"; 
while(my $line = <IN>) { 
  chomp $line;
  if($line =~ /^\# STOCKHOLM/) {
    print $line . "\n";
  }
  elsif($line =~ /^\#\=GF/) {
    print $line . "\n";
  }
  elsif($line =~ /^\#\=GS/) {
    print $line . "\n";
  }
  elsif($line =~ /^\/\//) { 
    print $line . "\n";
  }
  elsif($line =~ /^(\#\=GC RF)(\s+)(\S+)$/) { 
    my ($gc_rf, $space, $seq) = ($1, $2, $3);
    my $seq_5p = substr($seq, 0, $posn_for_insert);
    my $seq_3p = substr($seq, $posn_for_insert);
    my $new_seq = $seq_5p . $gap_to_add . $seq_3p;
    # and output the original RF
    printf("%s%s%s\n", $gc_rf, $space, $new_seq);
  }
  elsif($line =~ /^(\#\=GC)(\s+)(\S+)(\s+)(\S+)$/) { 
    my ($gc, $space1, $tag, $space2, $seq) = ($1, $2, $3, $4, $5);
    my $seq_5p = substr($seq, 0, $posn_for_insert);
    my $seq_3p = substr($seq, $posn_for_insert);
    my $new_seq = $seq_5p . $gap_to_add . $seq_3p;
    printf("%s%s%s%s%s\n", $gc, $space1, $tag, $space2, $new_seq);
  }
  elsif($line =~ /^(\#\=GR)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)$/) { 
    my ($gr, $space1, $seqname, $space2, $tag, $space3, $seq) = ($1, $2, $3, $4, $5, $6, $7);
    my $seq_5p = substr($seq, 0, $posn_for_insert);
    my $seq_3p = substr($seq, $posn_for_insert);
    my $new_seq = $seq_5p . $gap_to_add . $seq_3p;
    printf("%s%s%s%s%s\n", $gr, $space1, $seqname, $space2, $tag, $new_seq);
  }
  elsif($line =~ /^\#=/) {
    die "ERROR unrecognized #-prefixed line: $line\n";
  }
  elsif($line =~ /^(\S+)(\s+)(\S+)$/) { 
    my ($seqname, $space, $seq) = ($1, $2, $3);
    my $seq_5p = substr($seq, 0, $posn_for_insert);
    my $seq_3p = substr($seq, $posn_for_insert);
    my $new_seq = $seq_5p . $gap_to_add . $seq_3p;
    printf("%s%s%s\n", $seqname, $space, $new_seq);
    if($seqname eq $final_seqname) {
      # add the new seq(s)
      # determine the length of the space region
      my $new_space_len = length($space) - ($rfseq_to_add_name_length + length($opt_n) + 1 - length($seqname));
      if($new_space_len <= 0) { $new_space_len = 1; }
      my $new_space = "";
      for(my $z = 0; $z < $new_space_len; $z++) { $new_space .= " "; }
      for($a = 0; $a < $opt_n; $a++) { 
        printf("%s%s%s\n", $rfseq_to_add_name . "." . ($a+1), $new_space, $rfseq_to_add);
      }
    }
  }
  elsif($line =~ /^\s*$/) {
    print $line . "\n";
  }
  else {
    die "ERROR unrecognized line: $line\n";
  }
}
close(IN);

