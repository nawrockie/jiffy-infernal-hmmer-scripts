#!/usr/bin/env perl
## cmsearch --trmF3 --tblout format:
##sequence      modelname         score    start      end strand bounds ovp      seqlen
##------------- ---------------- ------ -------- -------- ------ ------ --- -----------
#AE00664.1      tRNA               18.7    48739    48814      +     ..  ?     2992245
# 
# cmsearch tblout output
#target name         accession query name           accession mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc description of target
#------------------- --------- -------------------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- ---------------------
#AE006641.1           -         tRNA                RF00005    cm        1       71    48739    48814      +    no    1 0.68   0.0   64.5   2.1e-11 !   Sulfolobus solfataricus P2, complete genome

while($line = <>) { 
  chomp $line;
  if($line !~ m/^#/) { 
    @el_A = split(/\s+/, $line);
    if(scalar(@el_A) == 9) { 
      ($seqname, $modelname, $score, $start, $stop, $strand, $bounds, $ovp, $seqlen) = ($el_A[0], $el_A[1], $el_A[2], $el_A[3], $el_A[4], $el_A[5], $el_A[6], $el_A[7], $el_A[8]);
    printf("$seqname - $modelname - hmm - - $start $stop $strand no 1 ? 0.0 $score 0 ! -\n");
    }
  }
}
