#!/usr/bin/env perl
# 
# fasta-to-subseq-fasta.pl: sample subsequences from sequences in an input fasta file
#                        
# EPN, Sun Mar 15 07:21:31 2020
# 
use strict;
use warnings;
use Getopt::Long;

my $usage = "perl fasta-to-subseq-fasta.pl\n";
$usage .= "\t<fasta file>\n";
$usage .= "\t<N: min length of a seq or 5' length to remove (if --nonrandom)>\n";
$usage .= "\t<X: max length of a seq or 3' length ro remove (if --nonrandom)>\n";
$usage .= "\t<num subseqs per seq (must be 1 if --nonrandom)>\n";
$usage .= "\t<rng seed>\n";
$usage .= "\t<output root for naming files>\n\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t-v          : print commands as they are run\n";
$usage .= "\t\t--nonrandom : do not randomly pick start/end, remove L/X residues from start/end\n";
$usage .= "\t\t--skipshort : silently skip any input seqs that are too short\n";
$usage .= "\n";

my $do_verbose = 0;
my $do_nonrandom = 0;
my $do_skipshort = 0;
&GetOptions( "v"         => \$do_verbose,
             "nonrandom" => \$do_nonrandom,
             "skipshort" => \$do_skipshort);

if(scalar(@ARGV) != 6) { die $usage; }

# cmd line args:
my $fasta_file; # input fasta file
my $N;          # minimum length of subseq, or if --nonrandom: num residues to chop off beginning of seq
my $X;          # maximum length of subseq, or if --nonrandom: num residues to chop off end of seq
my $nsub;       # number of subsequences to sample per input seq
my $rngseed = undef; # seed for RNG
my $out_root;   # output root for naming output files
($fasta_file, $N, $X, $nsub, $rngseed, $out_root) = (@ARGV);

if(($do_nonrandom) && ($nsub != 1)) { 
  die "ERROR with --nonrandom <num subseqs per seq> must be 1";
}
if(! $do_nonrandom) { 
  if($N > $X) { die "ERROR min len > max len"; }
}

my $seqstat_file = $out_root . ".a.seqstat";
my $cmd = "esl-seqstat -a $fasta_file > $seqstat_file";
run_command($cmd, $do_verbose);

# seed the RNG
srand($rngseed);

my $sfetch_file = $out_root . ".sfetch";
open(IN,          $seqstat_file) || die "ERROR unable to open $seqstat_file for reading";
open(SFETCH, ">", $sfetch_file)  || die "ERROR unable to open $sfetch_file for writing";
while(my $line = <IN>) { 
#= NC_037769.1/16167..17648      1482 YP_009487045.1
  if($line =~ m/^\=/) { 
    chomp $line;
    my @el_A = split(/\s+/, $line);
    my ($seqname, $length) = ($el_A[1], $el_A[2]);

    my $skip_this_seq = 0; # only possibly set to 1 if seq is too short and --skipshort enabled
    # check if they seq is too short
    if($do_nonrandom) { 
      if($length < ($N + $X + 1)) { 
        if($do_skipshort) { $skip_this_seq = 1; }
        else { die "ERROR sequence $seqname length is $length, too short to remove $N/$X residues from start/end"; }
      }
    }
    else { # randomly picking start/end
      if($length < $N) { 
        if($do_skipshort) { $skip_this_seq = 1; }
        else { die "ERROR sequence $seqname length is $length, too short to sample subseq of min length $N from"; }
      }
    }
    if(! $skip_this_seq) { 
      # not skipping this seq, sample or truncate
      # note: $nsub will be 1 if $do_nonrandom
      for(my $i = 0; $i < $nsub; $i++) { 
        
        my $sub_len = -1;      # length of subsequence
        my $sub_start = undef; # start position of subsequence
        my $sub_stop  = undef; # stop position of subsequence
        
        if($do_nonrandom) { 
          $sub_start = $N+1;
          $sub_stop  = $length - $X;
          $sub_len = $sub_stop - $sub_start + 1
        }
        else { # randomly pick start/end point
          while(($sub_len < $N) || ($sub_len > $X)) { 
            my $sub_r1 = int(rand($length)) + 1;
            my $sub_r2 = int(rand($length)) + 1;
            $sub_start = ($sub_r1 < $sub_r2) ? $sub_r1 : $sub_r2;
            $sub_stop  = ($sub_r1 < $sub_r2) ? $sub_r2 : $sub_r1;
            $sub_len = $sub_stop - $sub_start + 1;
          }
        }
        printf("seqname: $seqname length: $length $sub_start..$sub_stop sub_length:$sub_len\n");
        printf SFETCH ("$seqname/$sub_start-$sub_stop $sub_start $sub_stop $seqname\n");
      }
    }
  }
}
close(SFETCH);
my $index_cmd = "esl-sfetch --index $fasta_file"; 
run_command($index_cmd, $do_verbose);

my $subseq_file = $out_root . ".subseq.fa";
my $sfetch_cmd = "esl-sfetch -Cf $fasta_file $sfetch_file > $subseq_file";
run_command($sfetch_cmd, $do_verbose);

#######################################################
sub run_command {
  my $sub_name = "run_command()";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($cmd, $do_verbose) = (@_);
  
  if($do_verbose) { 
    print ("$cmd\n");
  }

  system($cmd);

  if($? != 0) { 
    die "ERROR in $sub_name, the following command failed:\n$cmd\n";
  }
    }
