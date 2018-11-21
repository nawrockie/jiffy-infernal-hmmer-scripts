#!/usr/bin/env perl
while($line = <>) { 
  ##target name         accession query name           accession mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc description of target
  ##------------------- --------- -------------------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- ---------------------
  #gi|255927625|gb|GQ303260.1| -         sim.all.YrlA.396.2   -          cm        1      105   128177   128297      +    no    1 0.58   0.0   32.1   0.00015 !   Mycobacterium phage ET08, complete gen  
  if($line !~ m/^\#/) { 
    chomp $line;
    @el_A = split(/\s+/, $line);
    if(scalar(@el_A) < 18) { die "ERROR less than 18 tokens on line $line"; }
    printf("%s/%d-%d %d %d %s\n", $el_A[0], $el_A[7], $el_A[8], $el_A[7], $el_A[8], $el_A[0]); 
  }
}

