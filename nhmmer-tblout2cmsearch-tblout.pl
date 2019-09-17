#!/usr/bin/env perl
# nhmmer 3.x --tblout format:
# target name        accession  query name           accession  hmmfrom hmm to alifrom  ali to envfrom  env to  sq len strand   E-value  score  bias  description of target
#------------------- ---------- -------------------- ---------- ------- ------- ------- ------- ------- ------- ------- ------ --------- ------ ----- ---------------------
#HyS0613              -          hsym.mito.8          -                1    5000   31501   36500   31501   36500   44906    +           0 4753.8 636.1  -
# 
# cmsearch tblout output
#target name         accession query name           accession mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc description of target
#------------------- --------- -------------------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- ---------------------
#HyS0613             -         hsym.mito.8          -         hmm        1     5000    31501    36500      +    no    1    ? 636.1 4753.8         0   ? -

while($line = <>) { 
  chomp $line;
  if($line !~ m/^#/) { 
    @el_A = split(/\s+/, $line);
    if(scalar(@el_A) <= 16) { 
      ($seqname, $modelname, $mdlfrom, $mdlto, $seqfrom, $seqto, $strand, $evalue, $score, $bias) = ($el_A[0], $el_A[2], $el_A[4], $el_A[5], $el_A[6], $el_A[7], $el_A[11], $el_A[12], $el_A[13], $el_A[14]);
      printf("$seqname - $modelname - hmm $mdlfrom $mdlto $seqfrom $seqto $strand no 1 ? $bias $score $evalue ! -\n");
    }
    else { 
      die "Did not read at least 18 tokens on nhmmer tblout line $line"; 
    }
  }
}
