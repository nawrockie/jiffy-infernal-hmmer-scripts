#!/usr/bin/env perl
# 
# cm-noss-force-match-states.pl: for a CM that is only MATL nodes, zero the transition probabilities into insertion states
#                                so that insertions become essentially impossible and match to match transitions are heavily
#                                favored.
#                        
# EPN, Fri Nov 14 11:04:43 2025
#
use strict;
use warnings;
use Getopt::Long;

my $usage .= "cm-noss-force-match-states.pl\n\n";
$usage    .= "Usage:\n";
$usage    .= "\tcm-noss-force-match-states.pl <CM with no secondary structure>\n";
$usage    .= "\n";

#&GetOptions( "s" => \$do_sumonly);

if(scalar(@ARGV) != 1) {
  die $usage;
}

my ($cmfile) = (@ARGV);

while(my $line = <>) {
  chomp $line;
  if($line =~ /\[\s+(\S+)\s+\d+\s+\]/) {
    my $ndtype = $1;
    if(($ndtype ne "ROOT") && ($ndtype ne "MATL") && ($ndtype ne "END")) {
      die "ERROR read unexpected node type $ndtype, expected CM with no secondary structure (and so only ROOT, MATL, and END nodes)";
    }
  }
  if($line =~ /^\s+S/) {
    # start state
    #S     0    -1 0     1     4     1     1    74   144 -15.615 -15.822  -0.000 -14.237                 
    if($line =~ /^\s+S(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)\s*$/) {
      my ($s1, $t1, $s2, $t2, $s3, $t3, $s4, $t4, $s5, $t5, $s6, $t6, $s7, $t7, $s8, $t8, $s9, $t9, $s10, $t10, $s11, $t11, $s12, $t12, $s13, $t13) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26);
      my ($s_to_il_trans, $s_to_ir_trans, $s_to_ml_trans, $s_to_d_trans) = ($t10, $t11, $t12, $t13);
      $s_to_il_trans = "-60.000"; # can't be '*' because then IL is unreachable and cmalign will crash
      $s_to_ir_trans = "      *";
      $s_to_ml_trans = " 0.000";
      $s_to_d_trans  = "      *";
      printf("     S%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s\n", $s1, $t1, $s2, $t2, $s3, $t3, $s4, $t4, $s5, $t5, $s6, $t6, $s7, $t7, $s8, $t8, $s9, $t9, $s10, $s_to_il_trans, $s11, $s_to_ir_trans, $s12, $s_to_ml_trans, $s13, $s_to_d_trans);
    }
    else {
      die "ERROR unable to parse S state line";
    }
  }
  elsif($line =~ /^\s+ML/) {
    # ML state
    # typical:
    #ML     3     2 3     5     3     1    13    74   144 -13.806  -0.000 -13.806                         -0.444 -1.013 -1.103  1.204
    if($line =~ /^\s+ML(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)\s*$/) { 
      my ($s1, $t1, $s2, $t2, $s3, $t3, $s4, $t4, $s5, $t5, $s6, $t6, $s7, $t7, $s8, $t8, $s9, $t9, $s10, $t10, $s11, $t11, $s12, $t12, $s13, $t13, $s14, $t14, $s15, $t15, $s16, $t16) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32);
      my ($ml_to_il_trans, $ml_to_ml_trans, $ml_to_d_trans) = ($t10, $t11, $t12);
      $ml_to_il_trans = "      *";
      $ml_to_ml_trans = " 0.000";
      $ml_to_d_trans  = "      *";
      printf("    ML%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s\n", $s1, $t1, $s2, $t2, $s3, $t3, $s4, $t4, $s5, $t5, $s6, $t6, $s7, $t7, $s8, $t8, $s9, $t9, $s10, $ml_to_il_trans, $s11, $ml_to_ml_trans, $s12, $ml_to_d_trans, $s13, $t13, $s14, $t14, $s15, $t15, $s16, $t16);
    }
    elsif($line =~ /^\s+ML(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)(\S+)(\s+)\s*$/) {
      # or the final ML before the END_E:
      #ML   108   107 3   110     2     1     1     1     1       *   0.000                                  0.320 -0.419 -0.018  0.023
      # we actually don't need to modify this line, should be ml->il = "*" ml->e = 0.000
      print $line . "\n";
    }
    else {
      die "ERROR unable to parse ML state line";
    }
  }
  else {
    print $line . "\n";
  }
}  
