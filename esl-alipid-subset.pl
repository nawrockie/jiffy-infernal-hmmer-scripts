#!/usr/bin/env perl
$usage =  "perl esl-alipid-subset.pl <list of seqs in group 1> <list of seqs in group 2> <alipid output file>\n\n";
$usage .= "The script will find the nearest neighbor in group 2 of all seqs in group 1.\n";
$usage .= "For example, group 1 might be the list of all non-SEED seqs from an Rfam alignment\n";
$usage .= "and group 2 would be all SEED seqs.\n";

if(scalar(@ARGV) != 3) { die $usage; };

my ($list_g1_file, $list_g2_file, $alipid_file) = (@ARGV);

open(LIST1, $list_g1_file) || die "ERROR unable to open $list_file";
my %name1_H = ();
my @name1_A = ();
my $width1 = length("#group1seq");
my $width2 = length("maxgroup2seq");
while($line = <LIST1>) { 
  chomp $line;
  push(@name1_A, $line);
  $name1_H{$line} = 1;
  $avg_H{$line} = 0.;
  $min_H{$line} = 100.;
  $max_H{$line} = 0.;
  $argmin_H{$line} = undef;
  $argmax_H{$line} = undef;
  $dnm_H{$line} = 0;
  if(length($line) > $width1) { 
    $width1 = length($line);
  }
}
close(LIST1);

open(LIST2, $list_g2_file) || die "ERROR unable to open $list_file";
my %name2_H = ();
my @name2_A = ();
while($line = <LIST2>) { 
  chomp $line;
  push(@name2_A, $line);
  $name2_H{$line} = 2;
  if(length($line) > $width2) { 
    $width2 = length($line);
  }
}
close(LIST2);

my %alipid_HA = ();
open(ALIPID, $alipid_file) || die "ERROR unable to open $alipid_file";

while($line = <ALIPID>) { 
  my($seq1, $seq2, $id1, $match1, $len1, $id2, $match2, $match2) = split(/\s+/, $line);
  $g1_seq = undef;
  $g2_seq = undef;
  if((exists $name1_H{$seq1}) && (exists $name2_H{$seq2})) { 
    $g1_seq = $seq1;
    $g2_seq = $seq2;
  }
  elsif((exists $name1_H{$seq2}) && (exists $name2_H{$seq1})) { 
    $g1_seq = $seq2;
    $g2_seq = $seq1;
  }
  if(defined $g1_seq) { 
    $avg_H{$g1_seq} += $id1;
    $dnm_H{$g1_seq}++;
    if($id1 > $max_H{$g1_seq}) { 
      $max_H{$g1_seq}    = $id1;
      $argmax_H{$g1_seq} = $g2_seq; 
    }
    if($id1 < $min_H{$g1_seq}) { 
      $min_H{$g1_seq}    = $id1;
      $argmin_H{$g1_seq} = $g2_seq; 
    }
  }    
}
close(ALIPID);

printf("%-*s  %6s  %-*s  %6s  %-*s  %6s\n", $width1, "#group1seq", "avgpid", $width2, "mingroup2seq", "minpid", $width2, "maxgroup2seq", "maxpid");
foreach $g1_seq (@name1_A) { 
  if(! defined $argmax_H{$g1_seq}) { 
    die "ERROR did not read any lines with $g1_seq\n";
  }
  printf("%-*s  %.3f  %-*s  %.3f  %-*s  %.3f\n", 
         $width1, $g1_seq, $avg_H{$g1_seq}/$dnm_H{$g1_seq}, 
         $width2, $argmin_H{$g1_seq}, $min_H{$g1_seq},
         $width2, $argmax_H{$g1_seq}, $max_H{$g1_seq});
}
