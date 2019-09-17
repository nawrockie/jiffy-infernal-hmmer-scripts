#!/usr/bin/env perl
$usage = "perl nhmmer-tblout-prune.pl <tblout file> <'S' or 'E' for bit score or E-value threshold> <threshold>";

if(scalar(@ARGV) != 3) { die $usage; }

($tblout_file, $s_or_e, $thresh) = (@ARGV);

if(($s_or_e ne "S") && ($s_or_e ne "E")) { 
  die "ERROR second cmd line argument must be 'S' (for bit score threshold) or 'E' (for E-value threshold)"
}
$do_bitsc = ($s_or_e eq "S") ? 1 : 0;

open(TBLOUT, $tblout_file) || die "ERROR unable to open $tblout_file";

while($line = <TBLOUT>) { 
  chomp $line;
  if($line !~ m/^\#/) { 
#     # Example line
#     # target name        accession  query name           accession  hmmfrom hmm to alifrom  ali to envfrom  env to  sq len strand   E-value  score  bias  description of target
#     #------------------- ---------- -------------------- ---------- ------- ------- ------- ------- ------- ------- ------- ------ --------- ------ ----- ---------------------
#     HyS0613              -          hsym.mito.8          -                1    5000   31501   36500   31501   36500   44906    +           0 4753.8 636.1  -
    @el_A = split(/\s+/, $line);
    if(scalar(@el_A) < 16) { die "ERROR less than 16 tokens on line $line"; }
    if   ((  $do_bitsc) && ($el_A[13] >= $thresh)) { print $line . "\n"; }
    elsif((! $do_bitsc) && ($el_A[12] <= $thresh)) { print $line . "\n"; }
  }
}

    
