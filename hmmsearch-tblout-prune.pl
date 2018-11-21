#!/usr/bin/env perl
$usage = "perl hmmsearch-tblout-prune.pl <tblout file> <'S' or 'E' for bit score or E-value threshold> <threshold>";

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
#     #                                                               --- full sequence ---- --- best 1 domain ---- --- domain number estimation ----
#     # target name        accession  query name           accession    E-value  score  bias   E-value  score  bias   exp reg clu  ov env dom rep inc description of target
#     #------------------- ---------- -------------------- ---------- --------- ------ ----- --------- ------ -----   --- --- --- --- --- --- --- --- ---------------------
#     5S_rRNA-sample10     -          5S_rRNA              RF00001      1.1e-19   59.8   0.0   1.2e-19   59.7   0.0   1.0   1   0   0   1   1   1   1 -
    @el_A = split(/\s+/, $line);
    if(scalar(@el_A) < 19) { die "ERROR less than 19 tokens on line $line"; }
    if   ((  $do_bitsc) && ($el_A[5] >= $thresh)) { print $line . "\n"; }
    elsif((! $do_bitsc) && ($el_A[4] <= $thresh)) { print $line . "\n"; }
  }
}

    
