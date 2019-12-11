#!/usr/bin/env perl
# tRNAscan-SE-v2.0.5 output:
#
# 6 possibilities (P1-P6) from v2.0.5
# 2 possibilities (P7,P8) from v1.2.3
# The script autodetects which format based on first two lines and parses accordingly.
# The script dies if autodetection fails (could be due to new format in new version of tRNAscan-SE).
# 
#
##########################################################################################################################
# Examples of P1-P8 formats
# First line of each section explains the version of tRNAscan-SE and 
# subsequent lines show the command line option combinations that cause the format. 
# E.g. "--detail && !-M && !--mt && !-H" means --detail option used and options -M, --mt and -H not used
# 
# Incompatible option combinations in v2.0.5:
# -H and -M 
# -M and --mt
#
##########################################################################################################################
# P1: v2.0.5 
# !--detail && !-H
# --detail && -M
#
#Sequence		tRNA   	Bounds 	tRNA	Anti	Intron Bounds	Inf	      
#Name    	tRNA #	Begin  	End    	Type	Codon	Begin	End	Score	Note
#--------	------	-----  	------ 	----	-----	-----	----	------	------
#HyE0021 	1	256691 	256764 	Asn	GTT	0	0	81.6	
##########################################################################################################################
# P2: v2.0.5 
# --detail && !-M && !--mt && !-H
#
#Sequence		tRNA   	Bounds 	tRNA	Anti	Intron Bounds	Inf	Isotype	Isotype	      
#Name    	tRNA #	Begin  	End    	Type	Codon	Begin	End	Score	CM	Score	Note
#--------	------	-----  	------ 	----	-----	-----	----	------	-------	-------	------
#HyE0021 	1	256691 	256764 	Asn	GTT	0	0	81.6	Asn	116.2	
##########################################################################################################################
# P3: v2.0.5
# --detail && --mt && !-H
#
#Sequence		tRNA   	Bounds 	tRNA	Anti	Intron Bounds	Inf	Isotype	Isotype	Type	      
#Name    	tRNA #	Begin  	End    	Type	Codon	Begin	End	Score	CM	Score	         	Note
#--------	------	-----  	------ 	----	-----	-----	----	------	-------	-------	---------	------
#HyE0021 	1	256691 	256764 	Asn	GTT	0	0	81.6	Asn	116.2	cytosolic	
##########################################################################################################################
# P4: v2.0.5
# -H && !--detail
#
#Sequence		tRNA   	Bounds 	tRNA	Anti	Intron Bounds	Inf	HMM	2'Str	      
#Name    	tRNA #	Begin  	End    	Type	Codon	Begin	End	Score	Score	Score	Note
#--------	------	-----  	------ 	----	-----	-----	----	------	-----	-----	------
#HyE0021 	1	256691 	256764 	Asn	GTT	0	0	81.6	56.40	25.20	
##########################################################################################################################
# P5: v2.0.5
# -H && --detail && !--mt
#
#Sequence		tRNA   	Bounds 	tRNA	Anti	Intron Bounds	Inf	HMM	2'Str	Isotype	Isotype	      
#Name    	tRNA #	Begin  	End    	Type	Codon	Begin	End	Score	Score	Score	CM	Score	Note
#--------	------	-----  	------ 	----	-----	-----	----	------	-----	-----	-------	-------	------
#HyE0021 	1	256691 	256764 	Asn	GTT	0	0	81.6	56.40	25.20	Asn	116.2	
##########################################################################################################################
# P6: v2.0.5
# -H && --detail && --mt
#
#Sequence		tRNA   	Bounds 	tRNA	Anti	Intron Bounds	Inf	HMM	2'Str	Isotype	Isotype	Type	      
#Name    	tRNA #	Begin  	End    	Type	Codon	Begin	End	Score	Score	Score	CM	Score	         	Note
#--------	------	-----  	------ 	----	-----	-----	----	------	-----	-----	-------	-------	---------	------
#HyE0021 	1	256691 	256764 	Asn	GTT	0	0	81.6	56.40	25.20	Asn	116.2	cytosolic	
##########################################################################################################################
# P7: v1.2.3 (same as P1, but no 'Note')
# !-H
# 
#Sequence     		tRNA 	Bounds	tRNA	Anti	Intron Bounds	Cove
#Name         	tRNA #	Begin	End  	Type	Codon	Begin	End	Score
#--------     	------	---- 	------	----	-----	-----	----	------
#AE006641.1 	1	48739  	48814  	Pro	TGG	0	0	93.0	
##########################################################################################################################
# P8: v1.2.3 (same as P4, but no 'Note')
# -H
# 
#Sequence     		tRNA 	Bounds	tRNA	Anti	Intron Bounds	Cove	HMM	2'Str
#Name         	tRNA #	Begin	End  	Type	Codon	Begin	End	Score	Score	Score
#--------     	------	---- 	------	----	-----	-----	----	------	-----	-----
#AE006641.1 	1	48739  	48814  	Pro	TGG	0	0	93.0	60.0    33.0    
##########################################################################################################################

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
$usage .= "\t\t-type      : set query to type field instead of tRNAscan-SE\n";
$usage .= "\t\t-E <s>     : set E-value field to <s> [default: 0]\n";

my $query = undef;
my $do_type = 0;
my $opt_E = undef;
&GetOptions( "query=s"  => \$query,
             "type"     => \$do_type,
             "E=s"      => \$opt_E);
if(! defined $query) { $query = "tRNAscan-SE"; }

if(scalar(@ARGV) != 1) { die $usage; }
($in_trnascan) = @ARGV;

my $format = undef; # set to "P1", "P2", ... "P8" when we read a header line
my $strand = undef;
my $evalue = undef;
open(IN, $in_trnascan) || die "ERROR unable to open $in_trnascan for reading";
while(my $line = <IN>) { 
  chomp $line;
  if($line =~ /^Sequence\s+tRNA\s+Bounds\s+tRNA\s+Anti\s+Intron\s+Bounds/) { 
    # if header line, determine the format (P1-P8)
    # we can have internal header lines (concatenated output files) but
    # only if they're the same format (we could actually handle it if they weren't
    # but current implementation fails if they're not)
    my $line1 = $line;
    my $line2 = <IN>;
    my $line3 = <IN>;
    my $cur_format = determine_format($line1, $line2);
    if((defined $format) && ($cur_format != $format)) { 
      die "ERROR detected multiple different formats in file (both $format and $cur_format).\nSee code for explanation of formats.\n"; 
    }
    $format = $cur_format;
  }
  elsif($line =~ m/\w/) { 
    if(! defined $format) { 
      die "ERROR format not yet determined and we read a data line"; 
    }
    my ($name, $idx, $start, $end, $type, $anticodon, $ibegin, $iend, 
        $score, $note, $isotype_cm, $isotype_score, $mt_type, $hmm_score, $str_score) = 
            parse_data_line($format, $line); 
    # build description:
    my $desc = "";
    if(defined $type) { 
      $desc .= "type=$type;";
    }
    if(defined $anticodon) { 
      $desc .= "anticodon=$anticodon;";
    }
    if(defined $ibegin) { 
      $desc .= "ibegin=$ibegin;";
    }
    if(defined $iend) { 
      $desc .= "iend=$iend;";
    }
    if(defined $hmm_score) { 
      $desc .= "hmm_score=$hmm_score;";
    }
    if(defined $str_score) { 
      $desc .= "str_score=$str_score;";
    }
    if(defined $isotype_cm) { 
      $desc .= "isotype_cm=$isotype_cm;";
    }
    if(defined $isotype_score) { 
      $desc .= "isotype_score=$isotype_score;";
    }
    if(defined $mt_type) { 
      $desc .= "mt_type=$mt_type;";
    }
    if(defined $note) { 
      $desc .= "note=$note;";
    }

    if($start <= $end) { $strand = "+"; }
    else               { $strand = "-"; }
    if($do_type) { $query = $type };
    $evalue = (defined $opt_E) ? $opt_E : "0";
    printf("%-30s - %-10s - cm - - %10d %10d %s no 1 ? 0.0 %7s $evalue ! $desc\n", $name, $query, $start, $end, $strand, $score);
  }
}
close(IN);

#################################################################
# Subroutine:  determine_format()
# Incept:      EPN, Wed Dec 11 11:09:37 2019
#
# Purpose:     Given two tRNAscan-SE header lines, determine the
#              format. 
#
# Arguments:
#   $line1:   first header line
#   $line2:   second header line
#
# Returns:    $format: "P1", "P2", "P3", "P4", "P5", "P6", "P7", or "P8"
#
# Dies:       If we can't figure out the format.
#################################################################
sub determine_format { 
  my $sub_name = "determine_format";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($line1, $line2) = @_;
  chomp $line1;
  chomp $line2;

  if($line1 =~ m/^Sequence\s+tRNA\s+Bounds\s+tRNA\s+Anti\s+Intron\s+Bounds\s+Inf\s*$/) { 
    if($line2 =~ m/^\Name\s+tRNA\s+\#\s+Begin\s+End\s+Type\s+Codon\s+Begin\s+End\s+Score\s+Note\s*$/) { 
      return "P1";
    }
    else { 
      die "ERROR P1 format second line mismatch\nline1:$line1\nline2:$line2\n";
    }
  }
  elsif($line1 =~ m/^Sequence\s+tRNA\s+Bounds\s+tRNA\s+Anti\s+Intron\s+Bounds\s+Inf\s+Isotype\s+Isotype\s*$/) { 
    if($line2 =~ m/Name\s+tRNA\s+#\s+Begin\s+End\s+Type\s+Codon\s+Begin\s+End\s+Score\s+CM\s+Score\s+Note\s*$/) { 
      return "P2";
    }
    else { 
      die "ERROR P2 format second line mismatch\nline1:$line1\nline2:$line2\n";
    }
  }
  elsif($line1 =~ m/^Sequence\s+tRNA\s+Bounds\s+tRNA\s+Anti\s+Intron\s+Bounds\s+Inf\s+Isotype\s+Isotype\s+Type\s*$/) { 
    if($line2 =~ m/Name\s+tRNA\s+#\s+Begin\s+End\s+Type\s+Codon\s+Begin\s+End\s+Score\s+CM\s+Score\s+Note\s*$/) { 
      return "P3";
    }
    else { 
      die "ERROR P3 format second line mismatch\nline1:$line1\nline2:$line2\n";
    }
  }
  elsif($line1 =~ m/^Sequence\s+tRNA\s+Bounds\s+tRNA\s+Anti\s+Intron\s+Bounds\s+Inf\s+HMM\s+2\'Str\s*$/) { 
    if($line2 =~ m/Name\s+tRNA\s+#\s+Begin\s+End\s+Type\s+Codon\s+Begin\s+End\s+Score\s+Score\s+Score\s+Note\s*$/) { 
      return "P4";
    }
    else { 
      die "ERROR P4 format second line mismatch\nline1:$line1\nline2:$line2\n";
    }
  }
  elsif($line1 =~ m/^Sequence\s+tRNA\s+Bounds\s+tRNA\s+Anti\s+Intron\s+Bounds\s+Inf\s+HMM\s+2\'Str\s+Isotype\s+Isotype\s*$/) { 
    if($line2 =~ m/Name\s+tRNA\s+#\s+Begin\s+End\s+Type\s+Codon\s+Begin\s+End\s+Score\s+Score\s+Score\s+CM\s+Score\s+Note\s*$/) { 
      return "P5";
    }
    else { 
      die "ERROR P5 format second line mismatch\nline1:$line1\nline2:$line2\n";
    }
  }
  elsif($line1 =~ m/^Sequence\s+tRNA\s+Bounds\s+tRNA\s+Anti\s+Intron\s+Bounds\s+Inf\s+HMM\s+2\'Str\s+Isotype\s+Isotype\s+Type\s*$/) { 
    if($line2 =~ m/Name\s+tRNA\s+#\s+Begin\s+End\s+Type\s+Codon\s+Begin\s+End\s+Score\s+Score\s+Score\s+CM\s+Score\s+Note\s*$/) { 
      return "P6";
    }
    else { 
      die "ERROR P6 format second line mismatch\nline1:$line1\nline2:$line2\n";
    }
  }
  elsif($line1 =~ m/^Sequence\s+tRNA\s+Bounds\s+tRNA\s+Anti\s+Intron\s+Bounds\s+Cove\s*$/) { 
    if($line2 =~ m/^\Name\s+tRNA\s+\#\s+Begin\s+End\s+Type\s+Codon\s+Begin\s+End\s+Score\s*$/) { 
      return "P7";
    }
    else { 
      die "ERROR P7 format second line mismatch\nline1:$line1\nline2:$line2\n";
    }
  }
    elsif($line1 =~ m/^Sequence\s+tRNA\s+Bounds\s+tRNA\s+Anti\s+Intron\s+Bounds\s+Cove\s+HMM\s+2\'Str\s*$/) { 
    if($line2 =~ m/^\Name\s+tRNA\s+\#\s+Begin\s+End\s+Type\s+Codon\s+Begin\s+End\s+Score\s+Score\s+Score\s*$/) { 
      return "P8";
    }
    else { 
      die "ERROR P8 format second line mismatch\nline1:$line1\nline2:$line2\n";
    }
  }
  else { 
    die "ERROR couldn't parse first header line\nline1:$line1\nline2:$line2\n";
  }
}

#################################################################
# Subroutine:  parse_data_line()
# Incept:      EPN, Wed Dec 11 10:51:06 2019
#
# Purpose:     Given an tRNAscan-SE -o output file line and 
#              its format, parse it and return info. 
#
# Arguments:
#   $format: "P1", "P2", "P3", "P4", "P5", "P6", "P7", or "P8"
#   $line:   line to parse
#
# Returns:    $name:          sequence name
#             $idx:           index of hit
#             $start:         start position of hit
#             $end:           end position of hit
#             $type:          tRNA type
#             $anticodon:     tRNA anticodon
#             $ibegin:        intron start position
#             $iend:          intron end position
#             $score:         Infernal/Cove score
#             $note:          note, can be "", undef for some formats
#             $isotype_cm:    name of isotype CM used, undef for some formats 
#             $isotype_score: isotype CM score, undef for some formats 
#             $mt_type:       second type, only if --mt, undef for some formats 
#             $hmm_score:     hmm score, undef for some formats
#             $str_score:     structure score, undef for some formats
#
# Dies:       If format is invalid or there's some problem parsing
#             the line.
#################################################################
sub parse_data_line { 
  my $sub_name = "parse_data_line";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($format, $line) = @_;
  
  my @el_A = split(/\s+/, $line);
  my $nel = scalar(@el_A);

  my $name          = undef;
  my $idx           = undef;
  my $start         = undef;
  my $end           = undef;
  my $type          = undef;
  my $anticodon     = undef;
  my $ibegin        = undef;
  my $iend          = undef;
  my $score         = undef;
  my $note          = undef;
  my $isotype_cm    = undef;
  my $isotype_score = undef;
  my $mt_type       = undef;
  my $hmm_score     = undef;
  my $str_score     = undef;

  if($format eq "P1") { 
    # P1: v2.0.5 
    # !--detail && !-H
    # --detail && -M
    #
    #Sequence		tRNA   	Bounds 	tRNA	Anti	Intron Bounds	Inf	      
    #Name    	tRNA #	Begin  	End    	Type	Codon	Begin	End	Score	Note
    #--------	------	-----  	------ 	----	-----	-----	----	------	------
    #HyE0021 	1	256691 	256764 	Asn	GTT	0	0	81.6	
    if(($nel != 9) && ($nel != 10)) { # Note may be empty
      die "ERROR P1 format in $sub_name, expects 9 or 10 tokens, got $nel\n$line\n";
    }
    if($nel == 9) { $el_A[9] = ""; } # add empty note if it's absent
    ($name, $idx, $start, $end, $type, $anticodon, $ibegin, $iend, $score, $note) = @el_A;
  }
  elsif($format eq "P2") { 
    # P2: v2.0.5 
    # --detail && !-M && !--mt && !-H
    #
    #Sequence		tRNA   	Bounds 	tRNA	Anti	Intron Bounds	Inf	Isotype	Isotype	      
    #Name    	tRNA #	Begin  	End    	Type	Codon	Begin	End	Score	CM	Score	Note
    #--------	------	-----  	------ 	----	-----	-----	----	------	-------	-------	------
    #HyE0021 	1	256691 	256764 	Asn	GTT	0	0	81.6	Asn	116.2	
    if(($nel != 11) && ($nel != 12)) { # Note may be empty
      die "ERROR P2 format in $sub_name, expects 11 or 12 tokens, got $nel\n$line\n";
    }
    if($nel == 11) { $el_A[11] = ""; } # add empty note if it's absent
    ($name, $idx, $start, $end, $type, $anticodon, $ibegin, $iend, $score, $isotype_cm, $isotype_score, $note) = @el_A;
  }
  elsif($format eq "P3") { 
    # P3: v2.0.5
    # --detail && --mt && !-H
    #
    #Sequence		tRNA   	Bounds 	tRNA	Anti	Intron Bounds	Inf	Isotype	Isotype	Type	      
    #Name    	tRNA #	Begin  	End    	Type	Codon	Begin	End	Score	CM	Score	         	Note
    #--------	------	-----  	------ 	----	-----	-----	----	------	-------	-------	---------	------
    #HyE0021 	1	256691 	256764 	Asn	GTT	0	0	81.6	Asn	116.2	cytosolic	
    if(($nel != 12) && ($nel != 13)) { # Note may be empty
      die "ERROR P3 format in $sub_name, expects 12 or 13 tokens, got $nel\n$line\n";
    }
    if($nel == 12) { $el_A[12] = ""; } # add empty note if it's absent
    ($name, $idx, $start, $end, $type, $anticodon, $ibegin, $iend, $score, $isotype_cm, $isotype_score, $mt_type, $note) = @el_A;
  }
  elsif($format eq "P4") { 
    # P4: v2.0.5
    # -H && !--detail
    #
    #Sequence		tRNA   	Bounds 	tRNA	Anti	Intron Bounds	Inf	HMM	2'Str	      
    #Name    	tRNA #	Begin  	End    	Type	Codon	Begin	End	Score	Score	Score	Note
    #--------	------	-----  	------ 	----	-----	-----	----	------	-----	-----	------
    #HyE0021 	1	256691 	256764 	Asn	GTT	0	0	81.6	56.40	25.20	
    if(($nel != 11) && ($nel != 12)) { # Note may be empty
      die "ERROR P4 format in $sub_name, expects 11 or 12 tokens, got $nel\n$line\n";
    }
    if($nel == 11) { $el_A[11] = ""; } # add empty note if it's absent
    ($name, $idx, $start, $end, $type, $anticodon, $ibegin, $iend, $score, $hmm_score, $str_score, $note) = @el_A;
  }
  elsif($format eq "P5") { 
    # P5: v2.0.5
    # -H && --detail && !--mt
    #
    #Sequence		tRNA   	Bounds 	tRNA	Anti	Intron Bounds	Inf	HMM	2'Str	Isotype	Isotype	      
    #Name    	tRNA #	Begin  	End    	Type	Codon	Begin	End	Score	Score	Score	CM	Score	Note
    #--------	------	-----  	------ 	----	-----	-----	----	------	-----	-----	-------	-------	------
    #HyE0021 	1	256691 	256764 	Asn	GTT	0	0	81.6	56.40	25.20	Asn	116.2	
    if(($nel != 13) && ($nel != 14)) { # Note may be empty
      die "ERROR P5 format in $sub_name, expects 13 or 14 tokens, got $nel\n$line\n";
    }
    if($nel == 13) { $el_A[13] = ""; } # add empty note if it's absent
    ($name, $idx, $start, $end, $type, $anticodon, $ibegin, $iend, $score, $hmm_score, $str_score, $isotype_cm, $isotype_score, $note) = @el_A;
  }
  elsif($format eq "P6") { 
    # P6: v2.0.5
    # -H && --detail && --mt
    #
    #Sequence		tRNA   	Bounds 	tRNA	Anti	Intron Bounds	Inf	HMM	2'Str	Isotype	Isotype	Type	      
    #Name    	tRNA #	Begin  	End    	Type	Codon	Begin	End	Score	Score	Score	CM	Score	         	Note
    #--------	------	-----  	------ 	----	-----	-----	----	------	-----	-----	-------	-------	---------	------
    #HyE0021 	1	256691 	256764 	Asn	GTT	0	0	81.6	56.40	25.20	Asn	116.2	cytosolic	
    if(($nel != 14) && ($nel != 15)) { # Note may be empty
      die "ERROR P6 format in $sub_name, expects 14 or 15 tokens, got $nel\n$line\n";
    }
    if($nel == 14) { $el_A[14] = ""; } # add empty note if it's absent
    ($name, $idx, $start, $end, $type, $anticodon, $ibegin, $iend, $score, $hmm_score, $str_score, $isotype_cm, $isotype_score, $mt_type, $note) = @el_A;
  }
  elsif($format eq "P7") { 
    # P7: v1.2.3 (same as P1, but no 'Note')
    # !-H
    # 
    #Sequence     		tRNA 	Bounds	tRNA	Anti	Intron Bounds	Cove
    #Name         	tRNA #	Begin	End  	Type	Codon	Begin	End	Score
    #--------     	------	---- 	------	----	-----	-----	----	------
    #AE006641.1 	1	48739  	48814  	Pro	TGG	0	0	93.0	
    if($nel != 9) { 
      die "ERROR P7 format in $sub_name, expects 9 tokens, got $nel\n$line\n";
    }
    ($name, $idx, $start, $end, $type, $anticodon, $ibegin, $iend, $score) = @el_A;
  }
  elsif($format eq "P8") { 
    # P8: v1.2.3 (same as P4, but no 'Note')
    # -H
    # 
    #Sequence     		tRNA 	Bounds	tRNA	Anti	Intron Bounds	Cove	HMM	2'Str
    #Name         	tRNA #	Begin	End  	Type	Codon	Begin	End	Score	Score	Score
    #--------     	------	---- 	------	----	-----	-----	----	------	-----	-----
    #AE006641.1 	1	48739  	48814  	Pro	TGG	0	0	93.0	60.0    33.0    
    if($nel != 11) { 
      die "ERROR P8 format in $sub_name, expects 11 tokens, got $nel\n$line\n";
    }
    ($name, $idx, $start, $end, $type, $anticodon, $ibegin, $iend, $score, $hmm_score, $str_score) = @el_A;
  }
  else { 
    die "ERROR unrecognized format $format in $sub_name\nline:$line\n";
  }

  return($name, $idx, $start, $end, $type, $anticodon, $ibegin, $iend, $score, $note, $isotype_cm, $isotype_score, $mt_type);
}
