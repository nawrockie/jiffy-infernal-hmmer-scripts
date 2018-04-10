# EPN, Tue Apr 10 06:42:41 2018
# bpinfo-count-compensatory-and-consistent.pl:
# Adds 10 columns to esl-alistat --bpinfo file.
#
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

@bp_A   = ("AA", "AC", "AG", "AU", "CA", "CC", "CG", "CU", "GA", "GC", "GG", "GU", "UA", "UC", "UG", "UU");
@iswc_A = (0,    0,    0,    1,    0,    0,    1,    0,    0,    1,    0,    0,    1,    0,    0,    0);
@isgu_A = (0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    1,    1,    0,    1,    0);
#     lpos     rpos    AA      AC      AG      AU      CA      CC      CG      CU      GA      GC      GG      GU      UA      UC      UG      UU  
#  -------  -------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------  ------
#        1      159       0       0       0       0       0       0       0       0       0       0       0       4       0       0       0       0
while($line = <>) { 
  if($line =~ m/^\/\/$/) { 
    print $line; 
  }
  elsif($line =~ m/^\#/) { 
    if($line =~ m/#\s+lpos/) { 
      # print explanation of columns:
      print("# extra column  1: '#wc|gu': number of Watson-Crick+GU+UG basepairs\n");
      print("# extra column  2: '#wc':    number of Watson-Crick basepairs\n");
      print("# extra column  3: '#gu':    number of GU+UG basepairs\n");
      print("# extra column  4: 'mc':     identity of most common basepair\n");
      print("# extra column  5: '#mc':    number of most common basepair\n");
      print("# extra column  6: '!#mc':   number of basepairs != most common basepair\n");
      print("# extra column  7: 'mcwcgu': 'yes' if most common basepair is WC or GU/UG, else 'no'\n");
      print("# extra column  8: '#comp':  if 'mcwcgu' is 'yes', number of compensatory (->WC) changes, else '-'\n");
      print("# extra column  9: '#cons':  if 'mcwcgu' is 'yes', number of consistent (->GU/UG) changes, else '-'\n");
      print("# extra column 10: '#incon': if 'mcwcgu' is 'yes', number of inconsistent (->non-WC/GU/UG) changes, else '-'\n");
      print("#\n");
      chomp $line;
      printf("%s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s\n", $line, "#wc|gu", "#wc", "#gu", "mc", "#mc", "#!mc", "mcwcgu", "#comp", "#cons", "#incon");
      $line = <>;
      chomp $line;
      printf("%s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s\n", $line, "------", "------", "------", "------", "------", "------", "------", "------", "------", "------");
    }
    else { 
      print $line;
    }
  }
  else { 
    # data line
    chomp $line;
    $orig_line = $line;
    $line =~ s/^\s+//;
    @el_A = split(/\s+/, $line);
    if(scalar(@el_A) != 18) { die "ERROR expected 18 tokens on data line but got a different number: $line\n"; }
    ($lpos, $rpos, $naa, $nac, $nag, $nau, $nca, $ncc, $ncg, $ncu, $nga, $ngc, $ngg, $ngu, $nua, $nuc, $nug, $nuu) = (@el_A);
    @nbp_A = ($naa, $nac, $nag, $nau, $nca, $ncc, $ncg, $ncu, $nga, $ngc, $ngg, $ngu, $nua, $nuc, $nug, $nuu);

    $nwc   = 0;
    $ngu   = 0;
    for($i = 0; $i < scalar(@nbp_A); $i++) { 
      $nwc += $iswc_A[$i] * $nbp_A[$i];
      $ngu += $isgu_A[$i] * $nbp_A[$i];
    }
    $nwcgu = $nwc + $ngu;

    # determine number of most common bp and what it is
    ($num_maxbp, $maxbp) = find_max_in_arr(\@nbp_A);
    # printf("num_maxbp: $num_maxbp, maxbp: $maxbp\n");

    # count up number of changes, consistent changes, compensatory changes, and inconsistent changes
    $ndiff = 0;
    $ncons = 0;
    $ncomp = 0;
    $nincons = 0;
    for($i = 0; $i < scalar(@nbp_A); $i++) { 
      if($i != $maxbp) { # not most common bp
        $ndiff += $nbp_A[$i];
        if($iswc_A[$i]) {  # watson crick
          $ncomp += $nbp_A[$i];
        }
        elsif($isgu_A[$i]) {  # ug or gu
          $ncons += $nbp_A[$i]; 
        }
        else { 
          $nincons += $nbp_A[$i];
        }
      }
    }

    # is most common bp a WC or GU/UG? 
    $mcwcgu = ($iswc_A[$maxbp] || $isgu_A[$maxbp]) ? 1 : 0;
    # if not, nullify consistent, compensatory and inconsistent changes
    if(! $mcwcgu) { 
      $ncons = "-";
      $ncomp = "-";
      $nincons = "-";
    }
    printf("%s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s  %6s\n", $orig_line, $nwcgu, $nwc, $ngu, $bp_A[$maxbp], $num_maxbp, $ndiff, ($mcwcgu) ? "yes" : "no", $ncomp, $ncons, $nincons);
  }
}

sub find_max_in_arr { 
  my $sub_name = "find_max_in_arr()";
  my $nargs_exp = 1;
  if(scalar(@_) != $nargs_exp) { die "ERROR $sub_name entered with wrong number of input args"; }

  my ($AR) = @_;
  $max    = $AR->[0];
  $argmax = 0;
  for($i = 1; $i < scalar(@{$AR}); $i++) { 
    if($AR->[$i] > $max) { 
      $max = $AR->[$i];
      $argmax = $i;
    }
  }
  return ($max, $argmax);
}
  
