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
$usage .= "\n";

my $max_evalue = undef;
my $min_bitsc  = undef;
my $do_cmscan  = 0;
&GetOptions( "e=s"     => \$max_evalue, 
             "t=s"     => \$min_bitsc, 
             "cmscan"  => \$do_cmscan);

if((defined $max_evalue) && 
   (defined $min_bitsc)) { 
  die "ERROR, -e and -t are incompatible, pick one";
}

if(scalar(@ARGV) != 1) { die $usage; }
my ($in_tblout) = @ARGV;

open(IN, $in_tblout) || die "ERROR, unable to open $in_tblout for reading";

my ($seqname, $start, $stop, $bitsc, $evalue);

while(my $line = <IN>) { 
  ## cmsearch:
  ##target name         accession query name           accession mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc description of target
  ##------------------- --------- -------------------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- ---------------------
  #gi|255927625|gb|GQ303260.1| -         sim.all.YrlA.396.2   -          cm        1      105   128177   128297      +    no    1 0.58   0.0   32.1   0.00015 !   Mycobacterium phage ET08, complete gen  
  ## 
  ## cmscan (target and query switched)
  ##target name         accession query name           accession mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc description of target
  ##------------------- --------- -------------------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- ---------------------
  #sim.all.YrlA.396.2   -         gi|255927625|gb|GQ303260.1   -          cm        1      105   128177   128297      +    no    1 0.58   0.0   32.1   0.00015 !   Mycobacterium phage ET08, complete gen  
  if($line !~ m/^\#/) { 
    chomp $line;
    my @el_A = split(/\s+/, $line);
    if(scalar(@el_A) < 18) { die "ERROR less than 18 tokens on line $line"; }
    $seqname = ($do_cmscan) ? $el_A[2] : $el_A[0];
    ($start, $stop, $bitsc, $evalue) = ($el_A[7], $el_A[8], $el_A[14], $el_A[15]);
    if(((! defined $max_evalue) || ($evalue <= $max_evalue)) &&
       ((! defined $min_bitsc)  || ($bitsc  >= $min_bitsc))) { 
      printf("%s/%d-%d %d %d %s\n", $seqname, $start, $stop, $start, $stop, $seqname);
    }
  }
}
close(IN);
