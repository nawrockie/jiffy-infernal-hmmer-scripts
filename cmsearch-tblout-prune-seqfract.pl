#!/usr/bin/env perl
$usage = "perl cmsearch-tblout-prune-seqfract.pl <Infernal v1.1x tblout file> <esl-seqstat -a output with all sequences> <min model fraction to keep>\n";
$usage .= "\n";
$usage .= "to make model length file: cmstat <cmfile> | grep -v ^\#  | awk '{ printf(\"\%s \%s\\n\", \$2, \$6); }'\n";
$usage .= "\n";

if(scalar(@ARGV) != 3) { die $usage; }

($tblout_file, $seqstat_file, $fractthresh) = (@ARGV);

my %seqlen_H = ();
open(SEQSTAT, $seqstat_file) || die "ERROR unable to open $seqstat_file for reading";
while($line = <SEQSTAT>) { 
  chomp $line;
#= Coll.siam.9093/1428-1546       119 Colletotrichum.siamense Eukaryota;Fungi;Dikarya;Ascomycota;Pezizomycotina;Sordariomycetes;Hypocreomycetidae;Glomerellales;Glomerellaceae;Colletotrichum;Colletotrichum gloeosporioides species complex MW929093.1
  if($line =~ /^\=\s+(\S+)\s+(\d+)/) { 
    my ($seqname, $len) = ($1, $2);
    $seqlen_H{$seqname} = $len;
  }
}
close(SEQSTAT);

open(TBLOUT, $tblout_file) || die "ERROR unable to open $tblout_file";
while($line = <TBLOUT>) { 
  chomp $line;
  if($line !~ m/^\#/) { 
##target name         accession query name           accession mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc description of target
##------------------- --------- -------------------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- ---------------------
#gi|255927625|gb|GQ303260.1| -         sim.all.YrlA.396.2   -          cm        1      105   128177   128297      +    no    1 0.58   0.0   32.1   0.00015 !   Mycobacterium phage ET08, complete genome
    @el_A = split(/\s+/, $line);
    if(scalar(@el_A) < 18) { die "ERROR less than 18 tokens on line $line"; }
    ($seqname, $mdlname, $seqfrom, $seqto) = ($el_A[0], $el_A[2], $el_A[7], $el_A[8]);
    if(! defined $seqlen_H{$seqname}) { die "ERROR read seq $seqname in tblout file not listed in $seqstat_file on line:$line"; }
    my $seqspan = abs($seqto - $seqfrom) + 1;
    my $seqfract = $seqspan / $seqlen_H{$seqname};
    if($seqfract >= $fractthresh) { 
      print $line . "\n"; 
    }
  }
}
close(TBLOUT);
    
