while($line = <>) { 
  if($line =~ /^\=/) { 
    chomp $line;
    @el_A = split(/\s+/, $line);
    ($seqname, $len) = ($el_A[1], $el_A[2]);
    printf("%s/%d-%d %d %d %s\n", $seqname, $len, 1, $len, 1, $seqname);
  }
}
