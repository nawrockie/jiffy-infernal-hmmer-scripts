
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
$usage .= "esl-seqstat-a2esl-sfetch-random-subseqs.pl <esl-seqstat -a output file> <length of subseqs (-1 for full seqs)> <number of subseqs>\n\n";

if(scalar(@ARGV) != 3) { die $usage; }
my ($seqstat_file, $target_len, $target_nseq) = @ARGV;

open(IN, $seqstat_file) || die "ERROR unable to open $seqstat_file for reading";

srand(42);


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
  elsif($seqlen >= $target_len) { 
    my $start = rand(($seqlen - $target_len)) + 1;
    my $stop  = $start + $target_len - 1;
    if($start < 1)       { die "ERROR got start ($start) < 1 for $seqname, len $seqlen"; }
    if($stop  > $seqlen) { die "ERROR got stop  ($stop)  > $seqlen for $seqname, len $seqlen"; }

    printf("%s/%d-%d %d %d %s\n", $seqname, $start, $stop, $start, $stop, $seqname);
    $i++;
  }
}
