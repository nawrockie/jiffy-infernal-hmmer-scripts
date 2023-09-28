#!/usr/bin/env perl
# EPN, Tue Sep 26 14:26:55 2023
# ali-multiseq-to-singleseq.pl
# Given an alignment position return the unaligned position that aligns to that alignment column
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "perl ali-multiseq-to-singleseq.pl [OPTIONS] <alignment file>\n\n";
#$usage .= "\tOPTIONS:\n";
#$usage .= "\t\t--notrf:   alignment position is overall position, not nongap RF (reference) position\n";

#my $do_notrf   = 0; # '1' to not operate in RF coordinate space
#&GetOptions( "notrf"   => \$do_notrf);

if(scalar(@ARGV) != 1) { die $usage; }

my ($aln_file) = (@ARGV);

# run esl-alistat --list to get list of all sequences:
my $line;
my $list_file = $aln_file . ".list";
runCommand("esl-alistat --list $list_file $aln_file > /dev/null", 0);
open(IN, "$list_file") || die "ERROR unable to open $list_file"; 
my @seq_A = ();
while($line = <IN>) { 
  chomp $line;
  push(@seq_A, $line);
}
close(IN);
unlink "$list_file";

# foreach sequence, run esl-alimanip --seq-k to save it to its own alignment file
for(my $i = 0; $i < scalar(@seq_A); $i++) { 
  my $seq = $seq_A[$i];
  my $i2use = $i+1;
  my $listfile = "$aln_file.list.$i2use";
  open(OUT, ">", $listfile) || die "ERROR unable to open $listfile for writing";
  print OUT $seq ."\n";
  close(OUT);
  runCommand("esl-alimanip --seq-k $listfile $aln_file > $aln_file.$i2use", 0);
  unlink $listfile;
  print("Saved single-sequence alignment with sequence $seq to $aln_file.$i2use\n");
}

#################################################################
# Subroutine:  runCommand()
# Incept:      EPN, Thu Feb 11 13:32:34 2016
#
# Purpose:     Runs a command using system() and exits in error 
#              if the command fails. If $be_verbose, outputs
#              the command to stdout.
#
# Arguments:
#   $cmd:         command to run, with a "system" command;
#   $be_verbose:  '1' to output command to stdout before we run it, '0' not to
#
# Returns:    void
#
# Dies:       if $cmd fails
#################################################################
sub runCommand {
  my $sub_name = "runCommand()";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($cmd, $be_verbose) = @_;
  
  if($be_verbose) { 
    print ("Running cmd: $cmd\n"); 
  }

  system($cmd);

  if($? != 0) { 
    die "ERROR, the following command failed:\n$cmd\n"; 
  }

  return;
}

#################################################################
# Subroutine:  parse_seqstat_a_file()
# Incept:      EPN, Fri May 25 14:04:48 2018
#
# Purpose:     Parses a esl-seqstat -a output file.
#
# Arguments:
#   $seqstat_file:  command to run, with a "system" command;
#   $name2check_AR: ref to array to check names against
#   $len_AR:        ref to array of sequence lengths to fill
#
# Returns:    void
#
# Dies:       if $cmd fails
#################################################################
sub parse_seqstat_a_file {
  my $sub_name = "parse_seqstat_a_file()";
  my $nargs_expected = 3;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($seqstat_file, $name2check_AR, $len_AR) = @_;

  open(IN, "$seqstat_file") || die "ERROR unable to open $seqstat_file";
  #= SSU_rRNA_bacteria-sample8        1 
  my $i = 0;
  my ($equal, $seqname, $length);
  while($line = <IN>) { 
    chomp $line;
    if($line =~ /^\=\s+\S+\s+\d+\s*.*$/) { 
      ($equal, $seqname, $length) = split(/\s+/, $line);
    }
    elsif($line =~ /^\=\s+0\s*$/) { 
      # length 0 
      ($equal, $length) = split(/\s+/, $line);
    }
    else { 
      die "ERROR unable to parse esl-seqstat -a line $line"; 
    }
    if($length ne "0") { 
      # esl-seqstat -a does not print sequence names for sequences of length 0
      if($name2check_AR->[$i] ne $seqname) { die sprintf("ERROR dealing with sequence #%d, name mismatch %s != %s\n", ($i+1), $name2check_AR->[$i], $seqname); }
    }
    $len_AR->[$i] = $length;
    $i++;
  }
  close(IN);
  
  return;
}
