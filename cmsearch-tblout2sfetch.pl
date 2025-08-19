#!/usr/bin/env perl
# 
# cmsearch-tblout2sfetch.pl: convert tblout file to esl-sfetch -Cf input file
#                        
# EPN, Thu Dec 26 06:26:06 2019
# 
use strict;
use warnings;
use Getopt::Long;

my $usage;
$usage  = "cmsearch-tblout2sfetch.pl\n\n";
$usage .= "Usage:\n";
$usage .= "\tcmsearch-tblout2sfetch.pl [OPTIONS]\n";
$usage .= "\t<tblout file>\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t-e <x>:   only keep hits with E-values <= <x>\n";
$usage .= "\t\t-t <x>:   only keep hits with bit scores >= <n>\n";
$usage .= "\t\t--cmscan: tblout file is from cmscan, not cmsearch\n";
$usage .= "\t\t--fmt2:   --fmt 2 used with cmscan (requires --cmscan)\n";
$usage .= "\n";

my $max_evalue = undef;
my $min_bitsc  = undef;
my $do_cmscan  = 0;
my $do_fmt2    = 0;
&GetOptions( "e=s"     => \$max_evalue, 
             "t=s"     => \$min_bitsc, 
             "cmscan"  => \$do_cmscan,
             "fmt2"    => \$do_fmt2);

if((defined $max_evalue) && 
   (defined $min_bitsc)) { 
  die "ERROR, -e and -t are incompatible, pick one";
}
if($do_fmt2 && (! $do_cmscan)) {
  die "ERROR, --fmt2 requires --cmscan"; 
}

if(scalar(@ARGV) != 1) { die $usage; }
my ($in_tblout) = @ARGV;

open(IN, $in_tblout) || die "ERROR, unable to open $in_tblout for reading";

my ($seqname, $start, $stop, $bitsc, $evalue);

while(my $line = <IN>) { 
  if($line !~ m/^\#/) { 
    chomp $line;
    my @el_A = split(/\s+/, $line);
    if($do_fmt2) { # --fmt2 used
      ##idx target name          accession query name           accession clan name mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc olp anyidx afrct1 afrct2 winidx wfrct1 wfrct2 mdl len seq len description of target
      ##--- -------------------- --------- -------------------- --------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- --- ------ ------ ------ ------ ------ ------ ------- ------- ---------------------
      #1    IE3                  -         NZ_CP101943.1        -         -          cm      198      229   483687   483718      + 5'&3'    5 0.81   0.0   13.9       1.3  ?   *       -      -      -      -      -      -     397 2703393 -
      #2    IE1                  -         NZ_CP101943.1        -         -          cm      180      245  1409788  1409705      - 5'&3'    5 0.73   0.2   10.4       8.2  ?   *       -      -      -      -      -      -     339 2703393 -
      #1    IC1                  -         NZ_LLYW01000001.1    -         -          cm      176      261    18178    18083      - 5'&3'    5 0.51   0.0   13.4    0.0095  !   *       -      -      -      -      -      -     385   60104 -
      if(scalar(@el_A) < 28) { die "ERROR less than 28 tokens on line $line"; }
      ($seqname, $start, $stop, $bitsc, $evalue) = ($el_A[3], $el_A[9], $el_A[10], $el_A[16], $el_A[17]);
    }
    else { # --fmt2 not used
      ## cmsearch:
      ##target name         accession query name           accession mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc description of target
      ##------------------- --------- -------------------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- ---------------------
      #gi|255927625|gb|GQ303260.1| -         sim.all.YrlA.396.2   -          cm        1      105   128177   128297      +    no    1 0.58   0.0   32.1   0.00015 !   Mycobacterium phage ET08, complete gen  
      ## 
      ## cmscan (target and query switched)
      ##target name         accession query name           accession mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc description of target
      ##------------------- --------- -------------------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- ---------------------
      #sim.all.YrlA.396.2   -         gi|255927625|gb|GQ303260.1   -          cm        1      105   128177   128297      +    no    1 0.58   0.0   32.1   0.00015 !   Mycobacterium phage ET08, complete gen  
      if(scalar(@el_A) < 18) { die "ERROR less than 18 tokens on line $line"; }
      $seqname = ($do_cmscan) ? $el_A[2] : $el_A[0];
      ($start, $stop, $bitsc, $evalue) = ($el_A[7], $el_A[8], $el_A[14], $el_A[15]);
    }
    if(((! defined $max_evalue) || ($evalue <= $max_evalue)) &&
       ((! defined $min_bitsc)  || ($bitsc  >= $min_bitsc))) { 
      printf("%s/%d-%d %d %d %s\n", $seqname, $start, $stop, $start, $stop, $seqname);
    }
  }
}
close(IN);
