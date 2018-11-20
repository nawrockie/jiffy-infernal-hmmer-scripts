$usage = "perl esl-alipid-per-seq-avg-pid.pl <alipid output file>";

if(scalar(@ARGV) != 1) { die $usage; };

my ($alipid_file) = (@ARGV);

my %pid_H   = ();
my %denom_H = ();
my @seq_A = ();
my %seq_H = ();
open(ALIPID, $alipid_file) || die "ERROR unable to open $alipid_file";

while($line = <ALIPID>) { 
  if($line !~ m/^\#/) { 
    ## seqname1 seqname2 %id nid denomid %match nmatch denommatch
    #AY743607.1 AY387239.1  94.61    527    557  90.15    540    599
    my($seq1, $seq2, $id1, $match1, $len1, $id2, $match2, $match2) = split(/\s+/, $line);
    $pid_H{$seq1} += $id1;
    $pid_H{$seq2} += $id1;
    $denom_H{$seq1}++;
    $denom_H{$seq2}++;
    if(! exists $seq_H{$seq1}) { 
      push(@seq_A, $seq1);
      $seq_H{$seq1} = 1;
    }
    if(! exists $seq_H{$seq2}) { 
      push(@seq_A, $seq2);
      $seq_H{$seq2} = 1;
    }
  }
}

foreach $seq (@seq_A) { 
  printf("%s %.3f\n", $seq, $pid_H{$seq} / $denom_H{$seq});
}

