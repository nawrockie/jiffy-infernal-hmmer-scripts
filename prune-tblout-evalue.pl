$usage = "perl prune-tblout-evalue.pl <tblout file> <E-value threshold>";

if(scalar(@ARGV) != 2) { die $usage; }

($tblout_file, $ecut) = (@ARGV);

open(TBLOUT, $tblout_file) || die "ERROR unable to open $tblout_file";

while($line = <TBLOUT>) { 
  chomp $line;
  if($line !~ m/^\#/) { 
##target name         accession query name           accession mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc description of target
##------------------- --------- -------------------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- ---------------------
#gi|255927625|gb|GQ303260.1| -         sim.all.YrlA.396.2   -          cm        1      105   128177   128297      +    no    1 0.58   0.0   32.1   0.00015 !   Mycobacterium phage ET08, complete genome
    @el_A = split(/\s+/, $line);
    if(scalar(@el_A) < 18) { die "ERROR less than 18 tokens on line $line"; }
    if($el_A[15] <= $ecut) { 
      print $line . "\n";
    }
  }
}

    
