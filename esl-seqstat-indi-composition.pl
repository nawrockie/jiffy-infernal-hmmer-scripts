my $usage = "perl esl-seqstat-indi-composition.pl <seqfile> <name for esl-seqstat -a output file>";
if(scalar(@ARGV) != 2) { 
  die $usage;
}
my ($seqfile, $statfile) = (@ARGV);

system("esl-seqstat -a $seqfile > $statfile");
if($? != 0) { die "ERROR esl-seqstat -a command failed"; }

# first get max seqname width
my $seqnamewidth = 0;
open(IN, $statfile) || die "ERROR unable to open $statfile for reading";
while($line = <IN>) { 
  if($line =~ /^\=/) { 
    chomp $line;
    @el_A = split(/\s+/, $line);
    ($seqname, $len) = ($el_A[1], $el_A[2]);
    if(length($seqname) > $seqnamewidth) { $seqnamewidth = length($seqname); }
  }
}
close(IN);

open(IN, $statfile) || die "ERROR unable to open $statfile for reading on second round";
while($line = <IN>) { 
  if($line =~ /^\=/) { 
    chomp $line;
    @el_A = split(/\s+/, $line);
    ($seqname, $len) = ($el_A[1], $el_A[2]);
    $seqname2fetch = $seqname;
    $seqname2fetch =~ s/\|/\\|/g;
    my $seqstat_c_output = `esl-sfetch $seqfile $seqname2fetch | esl-seqstat -c - | grep ^residue`;
    my @seqstat_c_A = split(/\n/, $seqstat_c_output);
    my $outline = "";
    foreach my $resline (@seqstat_c_A) { 
      if($resline =~ /^residue\:\s+(\S+)\s+(\d+)\s+(\S+)/) { 
        my($r, $n, $f) = ($1, $2, $3);
        my $tok = sprintf("%1s:[%6s]:%-10s", $r, $f, $n);
        $outline .= " " . $tok;
      }
      else { 
        die "ERROR unable to parse res line: $resline";
      }
    }
    printf("%-*s $outline\n", $seqnamewidth, $seqname);
  }
}
    
