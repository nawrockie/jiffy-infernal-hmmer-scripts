
#!/usr/bin/env perl
# 
# esl-seqstat-a2esl-sfetch-random-subseqs.pl\n\n";
#
# EPN, Wed Sep 29 18:25:52 2021
# 
#
use strict;
use warnings;
use Getopt::Long;

my $usage;
$usage  = "esl-seqstat-a2esl-sfetch-random-subseqs.pl\n\n";
$usage .= "Usage:\n\n";
$usage .= "esl-seqstat-a2esl-sfetch-random-subseqs.pl [OPTIONS] <esl-seqstat -a output file> <length of subseqs (-1 for full seqs)> <number of subseqs>\n\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t--seed <n> : set RNG seed as <n>\n";
$usage .= "\t\t--min  <n> : randomly sample lengths, and set minimum length as <n>, maximum as 2nd cmdline arg>\n";

my $seed = 42;         # changed if --seed is used
my $do_sample_len = 0; # set to '1' if --min used
my $min_len = undef;   # defined if --min used

&GetOptions( "seed=s"    => \$seed,
             "min=s"     => \$min_len);

if(scalar(@ARGV) != 3) { die $usage; }
my ($seqstat_file, $target_len, $target_nseq) = @ARGV;

if(($target_len == -1) && (defined $min_len)) { 
  die "ERROR with --min, 2nd cmdline arg can't be set as -1";
}
if((defined $min_len) && ($target_len <= $min_len)) { 
  die "ERROR with --min <n>, 2nd cmdline arg must be > $min_len";
}

if(defined $min_len) { 
  $do_sample_len = 1;
}

open(IN, $seqstat_file) || die "ERROR unable to open $seqstat_file for reading";

srand($seed);

my $seen_above_target_len = 0;
my @seqname_A = ();
my %seqlen_H = ();
while(my $line = <IN>) { 
  if($line =~ /^\=/) { 
    chomp $line;
    my @el_A = split(/\s+/, $line);
    my ($seqname, $len) = ($el_A[1], $el_A[2]);
    if(defined $seqlen_H{$seqname}) { 
      die "ERROR read sequence $seqname read more than once";
    }
    push(@seqname_A, $seqname);
    $seqlen_H{$seqname} = $len;
    if($len >= $target_len) { 
      $seen_above_target_len = 1;
    }
  }
}
my $nseq = scalar(@seqname_A);
if($nseq == 0) { 
  die "ERROR didn't read info on any seqs, is $seqstat_file an esl-seqstat -a output file?";
}
if(! $seen_above_target_len) { 
  die "ERROR did not see any seqs of length at least $target_len";
}

my $i = 0;
my $tries = 0;
my %newname_H = (); # used to keep track of new seq names, to avoid dups in output
while($i < $target_nseq) { 
  $tries++;
  if($tries > (1000 * $target_nseq)) { 
    die "ERROR unable to efficiently sample seqs, about 99.9% seem to be too short";
  }
  my $j = rand($nseq);
  my $seqname = $seqname_A[$j];
  my $seqlen  = $seqlen_H{$seqname};
  if($target_len == -1) { 
    printf("%s\n", $seqname);
    $i++;
  }
  else { 
    my $cur_target_len = $target_len;
    if($do_sample_len) { 
      $cur_target_len = $min_len + (rand(($target_len - $min_len) + 1) - 1);
    }
    if($seqlen >= $cur_target_len) { 
      my $start = rand(($seqlen - $cur_target_len)) + 1;
      my $stop  = $start + $cur_target_len - 1;
      if($start < 1)       { die "ERROR got start ($start) < 1 for $seqname, len $seqlen"; }
      if($stop  > $seqlen) { die "ERROR got stop  ($stop)  > $seqlen for $seqname, len $seqlen"; }
      
      my $newname = sprintf("%s/%d-%d", $seqname, $start, $stop);
      if(! defined $newname_H{$newname}) { 
        printf("%s %d %d %s\n", $newname, $start, $stop, $seqname);
        $i++;
        $newname_H{$newname} = 1;
      }
    }
  }
}
