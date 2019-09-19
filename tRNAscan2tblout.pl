#!/usr/bin/env perl
# tRNAscan-SE-v2.0 output:
#Sequence   		tRNA   	Bounds 	tRNA	Anti	Intron Bounds	Inf	      
#Name       	tRNA #	Begin  	End    	Type	Codon	Begin	End	Score	Note
#--------   	------	-----  	------ 	----	-----	-----	----	------	------
#AE006641.1 	1	48739  	48814  	Pro	TGG	0	0	93.0	
#
# OR (if -H):
#Sequence   		tRNA   	Bounds 	tRNA	Anti	Intron Bounds	Inf	HMM     2'Str 
#Name       	tRNA #	Begin  	End    	Type	Codon	Begin	End	Score	Score   Score   Note
#--------   	------	-----  	------ 	----	-----	-----	----	------	------  ------  ------
#AE006641.1 	1	48739  	48814  	Pro	TGG	0	0	93.0	60.0    33.0    
#
#  tRNAscan-SE-v1.23 output (same but no note):
#
#Sequence     		tRNA 	Bounds	tRNA	Anti	Intron Bounds	Cove
#Name         	tRNA #	Begin	End  	Type	Codon	Begin	End	Score
#--------     	------	---- 	------	----	-----	-----	----	------
#AE006641.1 	1	48739  	48814  	Pro	TGG	0	0	93.0	
#
# OR (if -H):
#
#Sequence     		tRNA 	Bounds	tRNA	Anti	Intron Bounds	Cove	HMM	2'Str
#Name         	tRNA #	Begin	End  	Type	Codon	Begin	End	Score	Score	Score
#--------     	------	---- 	------	----	-----	-----	----	------	-----	-----
#AE006641.1 	1	48739  	48814  	Pro	TGG	0	0	93.0	60.0    33.0    
# 
# # 
# cmsearch tblout output
#target name         accession query name           accession mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc description of target
#------------------- --------- -------------------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- ---------------------
#AE006641.1           -         tRNA                 RF00005    cm        1       71    48739    48814      +    no    1 0.68   0.0   64.5   2.1e-11 !   Sulfolobus solfataricus P2, complete genome
use strict;
use warnings;
use Getopt::Long;

my $in_trnascan  = "";   # name of input tblout file

my $usage;
$usage  = "tRNAscan2tblout.pl\n\n";
$usage .= "Usage:\n";
$usage .= "tRNAscan2tblout.pl [OPTIONS] <tRNAscan -o output (can be multiple files concatenated)>\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t-query <s> : set query to <s> instead of tRNAscan-SE\n";

my $query = undef;

&GetOptions( "query=s"  => \$query); 
if(! defined $query) { $query = "tRNAscan-SE"; }

if(scalar(@ARGV) != 1) { die $usage; }
($in_trnascan) = @ARGV;

open(IN, $in_trnascan) || die "ERROR unable to open $in_trnascan for reading";
while(my $line = <IN>) { 
  chomp $line;
  if($line =~m/Sequence\s+tRNA\s+Bounds\s+tRNA\s+Anti\s+Intron\s+Bounds/) { 
    # chomp up 3 header lines;
    $line = <IN>; 
    $line = <IN>;
  }
  else { 
    my ($name, $idx, $start, $end, $type, $anticodon, $intronstart, $intronend, $score, $note, $desc, $hmmsc, $structsc, $strand);
    $note = "";
    my @el_A = split(/\s+/, $line);
    if((scalar(@el_A) == 9) || (scalar(@el_A) == 10)) { # no -H
      ($name, $idx, $start, $end, $type, $anticodon, $intronstart, $intronend, $score, $note) = ($el_A[0], $el_A[1], $el_A[2], $el_A[3], $el_A[4], $el_A[5], $el_A[6], $el_A[7], $el_A[8], $el_A[9]);
      # $note may be undef
      if(! defined $note) { $note = ""; }
      if($type eq "Pseudo") { $note .= "pseudo"; } # only happens with version 1.23
      $desc = "type=$type;anti=$anticodon;istart=$intronstart;istop=$intronend;note=$note";
    }
    elsif((scalar(@el_A) == 11) || (scalar(@el_A) == 12)) { # -H
      ($name, $idx, $start, $end, $type, $anticodon, $intronstart, $intronend, $score, $hmmsc, $structsc, $note) = ($el_A[0], $el_A[1], $el_A[2], $el_A[3], $el_A[4], $el_A[5], $el_A[6], $el_A[7], $el_A[8], $el_A[9], $el_A[10], $el_A[11]);
      # $note may be undef
      if(! defined $note) { $note = ""; }
      if($type eq "Pseudo") { $note .= "pseudo"; } # only happens with version 1.23
      $desc = "type=$type;anti=$anticodon;istart=$intronstart;istop=$intronend;hmmsc=$hmmsc,structsc=$structsc,note=$note";
    }
    if($start <= $end) { $strand = "+"; }
    else               { $strand = "-"; }
    printf("$name - $query - cm - - $start $end $strand no 1 ? 0.0 $score 0 ! $desc\n");
  }
}
close(IN);
