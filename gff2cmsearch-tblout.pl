#!/usr/bin/env perl
# gff3 format:
# ref: https://github.com/The-Sequence-Ontology/Specifications/blob/master/gff3.md
# an important point of above ref:
# "Start is always less than or equal to end"
#seqname        source          feature start   end     score   strand  phase   attributes
#HyE0001	AUGUSTUS_PASA	exon	7231	7329	.	-	.	Parent=HyE0001.1
# 
# cmsearch tblout output
#target name         accession query name           accession mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc description of target
#------------------- --------- -------------------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- ---------------------
#HyE0001             -         -                    -         -   ?        ?        7329      7231         -    no    1    ?   0.0    0.0     100.0   ? feature:exon;attributes:Parent=HyE0001.1

while($line = <>) { 
  chomp $line;
  if(($line !~ m/^#/) && ($line !~ m/^\s*$/)) { 
    @el_A = split(/\s+/, $line);
    if(scalar(@el_A) == 9) { 
      ($seqname, $source, $feature, $start, $end, $score, $strand, $phase, $attributes) = (@el_A);
      my $desc2print  = "feature::$feature;;phase::$phase;;attributes::$attributes;;"; 
      my $start2print = ($strand eq "+") ? $start : $end;
      my $end2print   = ($strand eq "+") ? $end   : $start;
      my $score2print = 0.0;
      if(($score =~ m/^\d+$/) || ($score =~ m/^\d+\.\d+/)) { $score2print = $score; }
      printf("$seqname - - - - ? ? $start2print $end2print $strand no 1 ? 0.0 $score2print 100.0 ? $desc2print\n");
    }
    else { 
      die "Did not read exactly 9 lines on non-comment non-blank line $line";
    }
  }
}
