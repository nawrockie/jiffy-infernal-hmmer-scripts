#!/usr/bin/env perl
$usage = "perl esl-alipid-parse.pl <input list of accessions to find nearest neighbors for> <alipid output file> <output root>";

if(scalar(@ARGV) != 3) { die $usage; };

my ($list_file, $alipid_file, $out_root) = (@ARGV);

open(LIST, $list_file) || die "ERROR unable to open $list_file";
my %name_H = ();
my @name_A = ();
while($line = <LIST>) { 
  chomp $line;
  push(@name_A, $line);
  $name_H{$line} = 1;
}
close(LIST);

my %alipid_HA = ();
open(ALIPID, $alipid_file) || die "ERROR unable to open $alipid_file";

while($line = <ALIPID>) { 
  my($seq1, $seq2, $id1, $match1, $len1, $id2, $match2, $match2) = split(/\s+/, $line);
  if((exists $name_H{$seq1}) && (exists $name_H{$seq2})) { 
    $line = "IGNORE-SEED " . $line;
  }
  else { 
    $line = "INTERESTING " . $line;
  }

  if(exists $name_H{$seq1}) { 
    push(@{$alipid_HA{$seq1}}, $line);
  }
  if(exists $name_H{$seq2}) { 
    push(@{$alipid_HA{$seq2}}, $line);
  }
}
close(ALIPID);  

$file_ctr = 1;
foreach my $name (@name_A) { 
  $indi_file = $out_root . "." . $file_ctr . ".list";
  $sort_indi_file = "sort." . $out_root . "." . $file_ctr . ".list";
  open(OUT, ">", $indi_file) || die "ERROR unable to open output file $indi_file";
  foreach $line (@{$alipid_HA{$name}}) { 
    print OUT $line;
  }
  close(OUT);
  sleep(0.1);
  system("sort -rnk 4 $indi_file > $sort_indi_file");
  $file_ctr++;
}

