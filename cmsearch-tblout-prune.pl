#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

my $usage;
$usage  = "cmsearch-tblout-prune.pl\n\n";
$usage .= "Usage:\n";
$usage .= "\tcmsearch-tblout-prune.pl [OPTIONS]\n";
$usage .= "\t<Infernal v1.1x tblout file>\n";
$usage .= "\t<'S' or 'E' for bit score or E-value threshold>\n";
$usage .= "\t<threshold>\n\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t--fmt2 : tblout created using --fmt 2 option to cmsearch or cmscan\n";
if(scalar(@ARGV) != 3) { die $usage; }

my $do_fmt2 = 0;
&GetOptions( "fmt2" => \$do_fmt2);

my ($tblout_file, $s_or_e, $thresh) = (@ARGV);

if(($s_or_e ne "S") && ($s_or_e ne "E")) { 
  die "ERROR second cmd line argument must be 'S' (for bit score threshold) or 'E' (for E-value threshold)"
}

my $do_bitsc = ($s_or_e eq "S") ? 1 : 0;

open(TBLOUT, $tblout_file) || die "ERROR unable to open $tblout_file";

while(my $line = <TBLOUT>) { 
  chomp $line;
  if($line !~ m/^\#/) { 
    my @el_A = split(/\s+/, $line);
    if(scalar(@el_A) < 18) { die "ERROR less than 18 tokens on line $line"; }
    if($do_fmt2) { # --fmt2 used
      ##idx target name          accession query name           accession clan name mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc olp anyidx afrct1 afrct2 winidx wfrct1 wfrct2 mdl len seq len description of target
      ##--- -------------------- --------- -------------------- --------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- --- ------ ------ ------ ------ ------ ------ ------- ------- ---------------------
      #1    IE3                  -         NZ_CP101943.1        -         -          cm      198      229   483687   483718      + 5'&3'    5 0.81   0.0   13.9       1.3  ?   *       -      -      -      -      -      -     397 2703393 -
      #2    IE1                  -         NZ_CP101943.1        -         -          cm      180      245  1409788  1409705      - 5'&3'    5 0.73   0.2   10.4       8.2  ?   *       -      -      -      -      -      -     339 2703393 -
      #1    IC1                  -         NZ_LLYW01000001.1    -         -          cm      176      261    18178    18083      - 5'&3'    5 0.51   0.0   13.4    0.0095  !   *       -      -      -      -      -      -     385   60104 -
      if   ((  $do_bitsc) && ($el_A[16] >= $thresh)) { print $line . "\n"; }
      elsif((! $do_bitsc) && ($el_A[17] <= $thresh)) { print $line . "\n"; }
    }
    else { # --fmt2 not used
      ##target name         accession query name           accession mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc description of target
      ##------------------- --------- -------------------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- ---------------------
      #gi|255927625|gb|GQ303260.1| -         sim.all.YrlA.396.2   -          cm        1      105   128177   128297      +    no    1 0.58   0.0   32.1   0.00015 !   Mycobacterium phage ET08, complete genome
      if   ((  $do_bitsc) && ($el_A[14] >= $thresh)) { print $line . "\n"; }
      elsif((! $do_bitsc) && ($el_A[15] <= $thresh)) { print $line . "\n"; }
    }
  }
}

    
