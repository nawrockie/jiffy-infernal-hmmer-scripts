#!/usr/bin/env perl
# EPN, Tue Apr 10 06:42:41 2018
# esl-alistat-bpinfo-count-compensatory-and-consistent.pl:
# Adds 10 columns to esl-alistat --bpinfo file.
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "perl esl-alistat-bpinfo-count-compensatory-and-consistent.pl [OPTIONS] <bpinfo file>\n\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t-t : print total counts, not per line counts";

my $do_total = 0;
&GetOptions( "t" => \$do_total);

if(scalar(@ARGV) != 1) { die $usage; }

my ($bpinfo_file) = (@ARGV);
open(BPINFO, $bpinfo_file) || die "ERROR unable to open $bpinfo_file";

#######
# Beginning of bpinfo file
## Per-column basepair counts:
## Alignment file: refine.cmbuild.raf.s8.i2.ybs.all.refine.cmbuild.stk
## Alignment idx:  1
## Alignment name: s8.i2.ybs.all.cmalign
## Number of sequences: 4
## Only basepairs involving two canonical (non-degenerate) residues were counted.
## Sequence weights from alignment were ignored (if they existed).
##
##       lpos     rpos    AA      AC      AG      AU      CA      CC      CG      CU      GA      GC      GG      GU      UA      UC      UG      UU  
##    -------  -------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------
#        1      159       0       0       0       0       0       0       0       0       0       0       0       4       0       0       0       0

my @bp_A   = ("AA", "AC", "AG", "AU", "CA", "CC", "CG", "CU", "GA", "GC", "GG", "GU", "UA", "UC", "UG", "UU");
my @iswc_A = (0,    0,    0,    1,    0,    0,    1,    0,    0,    1,    0,    0,    1,    0,    0,    0);
my @isgu_A = (0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    1,    0,    0,    1,    0);
#     lpos     rpos    AA      AC      AG      AU      CA      CC      CG      CU      GA      GC      GG      GU      UA      UC      UG      UU  
#  -------  -------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------
#        1      159       0       0       0       0       0       0       0       0       0       0       0       4       0       0       0       0
my $line;
my $ndiff_nt = 0;
my $ndiff_bp = 0;
my $ncomp = 0;
my $ncons = 0;
my $nincons = 0;
my $nchanges = 0;
my $i;
my $total_bps = 0;
my $total_num_bps = 0;
my $total_num_maxbp = 0;
my $total_ndiff_nt = 0;
my $total_ndiff_bp = 0;
my $total_ncons = 0;
my $total_ncomp = 0;
my $total_nincons = 0;
my $total_nwcgu = 0;
my $total_nwc = 0;
my $total_ngu = 0;
while($line = <BPINFO>) { 
  if($line =~ m/^\/\/$/) { 
    if(! $do_total) { 
      print $line;  
    }
  }
  elsif($line =~ m/^\#/) { 
    if($line =~ m/#\s+lpos/) { 
      if(! $do_total) { 
        # print explanation of columns:
        print("# extra column  1: '#wc|gu': number of Watson-Crick+GU+UG basepairs\n");
        print("# extra column  2: '#wc':    number of Watson-Crick basepairs\n");
        print("# extra column  3: '#gu':    number of GU+UG basepairs\n");
        print("# extra column  4: 'mc':     identity of most common basepair\n");
        print("# extra column  5: '#mc':    number of most common basepair\n");
        print("# extra column  6: '#bp!mc': number of basepairs != most common basepair\n");
        print("# extra column  6: '#nt!mc': number of nucleotide changes in basepairs != most common basepair\n");
        print("# extra column  8: 'mcwcgu': 'yes' if most common basepair is WC or GU/UG, else 'no'\n");
        print("# extra column  9: '#comp':  if 'mcwcgu' is 'yes', number of compensatory nucleotide changes to WC or GU/UG (2 per each mutated basepair), else '-'\n");
        print("# extra column 10: '#cons':  if 'mcwcgu' is 'yes', number of consistent nucleotide changes to WC or GU/UG (1 per each mutated basepair), else '-'\n");
        print("# extra column 11: '#incon': if 'mcwcgu' is 'yes', number of inconsistent changes to non-WC/GU/UG (1 or 2 per each mutated basepair), else '-'\n");
        print("#\n");
        chomp $line;
        printf("%s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s\n", $line, "#wc|gu", "#wc", "#gu", "mc", "#mc", "#bp!mc", "#nt!mc", "mcwcgu", "#comp", "#cons", "#incon");
        $line = <BPINFO>;
        chomp $line;
        printf("%s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s\n", $line, "------", "------", "------", "------", "------", "------", "------", "------", "------", "------", "------");
      }
    }
    else { 
      if(! $do_total) { 
        print $line;
      }
    }
  }
  else { 
    # data line
    chomp $line;
    my $orig_line = $line;
    $line =~ s/^\s+//;
    my @el_A = split(/\s+/, $line);
    if(scalar(@el_A) != 18) { die "ERROR expected 18 tokens on data line but got a different number: $line\n"; }
    my ($lpos, $rpos, $naa, $nac, $nag, $nau, $nca, $ncc, $ncg, $ncu, $nga, $ngc, $ngg, $ngu, $nua, $nuc, $nug, $nuu) = (@el_A);
    my @nbp_A = ($naa, $nac, $nag, $nau, $nca, $ncc, $ncg, $ncu, $nga, $ngc, $ngg, $ngu, $nua, $nuc, $nug, $nuu);
    
    my $nwc   = 0;
    $ngu   = 0;
    for($i = 0; $i < scalar(@nbp_A); $i++) { 
      $nwc += $iswc_A[$i] * $nbp_A[$i];
      $ngu += $isgu_A[$i] * $nbp_A[$i];
    }
    my $nwcgu = $nwc + $ngu;
    
    # determine number of most common bp and what it is
    my ($num_maxbp, $maxbp) = find_max_in_bp_arr(\@nbp_A);
    # printf("num_maxbp: $num_maxbp, maxbp: $maxbp\n");
    
    # is most common bp a WC or GU/UG? 
    my $mcwcgu = ($iswc_A[$maxbp] || $isgu_A[$maxbp]) ? 1 : 0;
    
    if($mcwcgu) { 
      # count up number of changes, consistent changes, compensatory changes, and inconsistent changes
      $ndiff_nt = 0;
      $ndiff_bp = 0;
      $ncons = 0;
      $ncomp = 0;
      $nincons = 0;
      for($i = 0; $i < scalar(@nbp_A); $i++) { 
        if($i != $maxbp) { # not most common bp
          $nchanges = num_changes_between_two_basepairs($bp_A[$i], $bp_A[$maxbp]);
          $ndiff_nt += $nchanges * $nbp_A[$i];
          $ndiff_bp += $nbp_A[$i];
          if(($iswc_A[$i]) || ($isgu_A[$i])) {
            if($nchanges == 2) { 
              $ncomp += $nbp_A[$i] * 2; 
            }
            elsif($nchanges == 1) { 
              $ncons += $nbp_A[$i] * 1; 
            }
            else { 
              die "ERROR got zero changes: i: $i line: $line\n";
            }
          }
          else { # not WC or GU/UG
            $nincons += $nbp_A[$i] * $nchanges;
          }
        }
      }
    }
    else {  # not wc or gu
      # nullify consistent, compensatory and inconsistent changes
      $ncons = "-";
      $ncomp = "-";
      $nincons = "-";
    }
    if(! $do_total) { 
      printf("%s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s\n", $orig_line, $nwcgu, $nwc, $ngu, $bp_A[$maxbp], $num_maxbp, $ndiff_bp, $ndiff_nt, ($mcwcgu) ? "yes" : "no", $ncomp, $ncons, $nincons);
    }
    $total_bps++;
    $total_num_bps += $num_maxbp + $ndiff_bp;
    $total_num_maxbp += $num_maxbp;
    $total_ndiff_nt += $ndiff_nt;
    $total_ndiff_bp += $ndiff_bp;
    if($mcwcgu) { 
      $total_ncomp += $ncomp;
      $total_ncons += $ncons;
      $total_nincons += $nincons;
    }
    $total_nwcgu += $nwcgu;
    $total_nwc += $nwc;
    $total_ngu += $ngu;
  }
}
close(BPINFO);
    
if($do_total) { 
  print("# column 1: '#wc|gu': number of Watson-Crick+GU+UG basepairs\n");
  print("# column 2: '#wc':    number of Watson-Crick basepairs\n");
  print("# column 3: '#gu':    number of GU+UG basepairs\n");
  print("# column 4: '#mc':    number of most common basepair\n");
  print("# column 5: '#bp!mc': number of basepairs != most common basepair\n");
  print("# column 6: '#nt!mc': number of nucleotide changes in basepairs != most common basepair\n");
  print("# column 7: '#comp':  if 'mcwcgu' is 'yes', number of compensatory nucleotide changes to WC or GU/UG (2 per each mutated basepair), else '-'\n");
  print("# column 8: '#cons':  if 'mcwcgu' is 'yes', number of consistent nucleotide changes to WC or GU/UG (1 per each mutated basepair), else '-'\n");
  print("# column 9: '#incon': if 'mcwcgu' is 'yes', number of inconsistent changes to non-WC/GU/UG (1 or 2 per each mutated basepair), else '-'\n");
  printf("%6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s\n", "#wc|gu", "#wc", "#gu", "#mc", "#bp!mc", "#nt!mc", "#comp", "#cons", "#incon");
  printf("%6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s\n", $total_nwcgu, $total_nwc, $total_ngu, $total_num_maxbp, $total_ndiff_bp, $total_ndiff_nt, $total_ncomp, $total_ncons, $total_nincons);
}

sub find_max_in_bp_arr { 
  my $sub_name = "find_max_in_bp_arr()";
  my $nargs_exp = 1;
  if(scalar(@_) != $nargs_exp) { die "ERROR $sub_name entered with wrong number of input args"; }

  my ($AR) = @_;

  my $max;
  my $argmax;

  # look at non-watson crick non-gu first, so that they are considered dominant bp
  # if there is a tie with them and another WC or GU/UG and that basepair is then not counted
  my @order_A = (0, 1, 2, 4, 5, 7, 8, 10, 13, 15, 3, 6, 9, 11, 12, 14);
  #AA AC AG CA CC CU GA GG  UC  UU  AU CG GC GU  UA UG

  if(scalar(@{$AR}) != scalar(@order_A)) { die "ERROR different array sizes in $sub_name"; }
  $max = $AR->[$order_A[0]];
  $argmax = $order_A[0];
  for($i = 1; $i < scalar(@{$AR}); $i++) { 
    if($AR->[$order_A[$i]] > $max) { 
      $max = $AR->[$order_A[$i]];
      $argmax = $order_A[$i];
    }
  }
  return ($max, $argmax);
}

sub num_changes_between_two_basepairs { 
  my $sub_name = "num_changes_between_two_basepairs";
  my $nargs_exp = 2;
  if(scalar(@_) != $nargs_exp) { die "ERROR $sub_name entered with wrong number of input args"; }

  my ($bp1, $bp2) = @_;

  my @ntA1 = split("", $bp1);
  my @ntA2 = split("", $bp2);
  if(scalar(@ntA1) != 2) { die "ERROR in $sub_name, weird bp $bp1"; }
  if(scalar(@ntA2) != 2) { die "ERROR in $sub_name, weird bp $bp1"; }

  my $nchanges = 0;
  if($ntA1[0] ne $ntA2[0]) { $nchanges++; }
  if($ntA1[1] ne $ntA2[1]) { $nchanges++; }

  return $nchanges;
}

