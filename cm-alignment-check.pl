#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

my $opt_thresh = undef;
my $thresh = 0.00100001; # default, overwritten with --thresh

my $usage;
$usage = "cm-alignment-check.pl\n\n";
$usage .= "Usage:\n";
$usage .= "cm-alignment-check.pl [OPTIONS] <Infernal v1.1x CM file> <stockholm alignment to check if it was used with cmbuild to create the CM>\n\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t--thresh <f>: set tolerated difference in floating point parameters in CM file to <f> [df: $thresh]\n\n";


&GetOptions( "thresh"   => \$opt_thresh);

if(defined $opt_thresh) { $thresh = $opt_thresh; }

if(scalar(@ARGV) != 2) { die $usage; }
my ($in_cmfile, $in_alnfile) = @ARGV;

# parse cm file
my ($in_cksum, $in_cmbuild_opts) = parse_cmfile($in_cmfile);

printf("Input CM file:        $in_cmfile\n");
printf("Input Alignment file: $in_alnfile\n");

# build temporary CM
if($in_cmbuild_opts !~ m/-F\s+/) { 
  $in_cmbuild_opts .= " -F ";
}
my $tmp_cm1 = "tmp1." . $$ . ".cm";
system("cmbuild $in_cmbuild_opts $tmp_cm1 $in_alnfile > /dev/null");
if($? != 0) { 
  die "ERROR, unable to build temporary CM file tmp.cm";
}

# parse temporary CM
my ($tmp_cksum, undef) = parse_cmfile($tmp_cm1);

# remove lines from CM we don't want to compare
my $tmp_cm2 = "tmp2." . $$ . ".cm";
my $in_cm2  = "in2."  . $$ . ".cm";
strip_cmfile($tmp_cm1, $tmp_cm2);
strip_cmfile($in_cmfile, $in_cm2);

# diff the files
my $diff_output = `diff $in_cm2 $tmp_cm2`;

my $fail = 0;
if($in_cksum ne $tmp_cksum) { 
  printf("CHECKSUM mismatch $in_cksum != $tmp_cksum\n");
  $fail = 1;
}

# check the diff output and see if it is acceptable
my ($ndiff_tokens, $diff_err_str) = check_diff_output($diff_output, $thresh);

if($diff_err_str ne "") { 
  print ("Diff unacceptable:\n$diff_err_str\n");
  $fail = 1; 
}

if($fail == 0) { 
  printf("Check successful: $in_cmfile created alignment in $in_alnfile ($ndiff_tokens floating point values differed but within allowed threshold of $thresh)\n");
  unlink $tmp_cm1;
  unlink $tmp_cm2;
  unlink $in_cm2;
}

exit $fail;
    
#################################################################
# Subroutine : parse_cmfile()
# Incept:      EPN, Wed Oct 10 12:31:43 2018
#
# Purpose:     Parse a CM file
#
# Arguments:   $cmfile: name of cmfile
# 
# Returns:     $cksum: checksum read from CM file
#              $cmbuild_opts: cmbuild options used to build CM
#
# Dies:        If $cmfile has more than 1 CM.
#              If no CKSUM line is read
#              If no INFERNAL line is read
#              If no COM cmbuild line is read
#              If unable to open $cmfile
#
################################################################# 
sub parse_cmfile { 
  my $nargs_expected = 1;
  my $sub_name = "parse_cmfile";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($in_cmfile) = (@_);

  my $cksum        = undef;
  my $cmbuild_opts = undef;
  my $version      = undef;
  my $ncksum_read   = 0;
  my $ncmbuild_read = 0;
  my $nversion_read = 0;
  open(CM, $in_cmfile) || die "ERROR unable to open $in_cmfile";
  while(my $line = <CM>) { 
    chomp $line;
    if($line =~ m/^(INFERNAL\S+)/) { 
      $nversion_read++;
      if($nversion_read > 1) { 
        die "ERROR read two version lines, CM file must have exactly 1 CM in it";
      }
      $version = $1;
      if($version ne "INFERNAL1/a") { 
        warn "Warning: expected version INFERNAL1/a but got $version, this script may not work for this CM file format";
      }
    }
    elsif($line =~ m/^COM\s+\[\d+]\s+.*(cmbuild.+)$/) {
      # parse out cmbuild options used
      $ncmbuild_read++;
      #if($ncmbuild_read > 2) { 
      #  die "ERROR read more than two COM cmbuild lines, CM file must have exactly 1 CM in it";
      #}
      my $cmbuild_cmd = $1;
      my @cmbuild_A = split(/\s+/, $cmbuild_cmd);
      my $tmp_cmbuild_opts = "";
      if(scalar(@cmbuild_A) > 3) { # at least 1 command line option used
        for(my $i = 1; $i < (scalar(@cmbuild_A) - 2); $i++) { 
          $tmp_cmbuild_opts .= $cmbuild_A[$i] . " ";
        }
      }
      if($ncmbuild_read > 1) { 
        if($cmbuild_opts ne $tmp_cmbuild_opts) { 
          die "ERROR, read two different cmbuild options lines: $cmbuild_opts and $tmp_cmbuild_opts"; 
        }
      }
      $cmbuild_opts = $tmp_cmbuild_opts;
    }
    elsif($line =~ m/^CKSUM\s+(\S+)/) { 
      my $tmp_cksum = $1;
      $ncksum_read++;
      if($ncksum_read > 2) {
        die "ERROR read more than two CKSUM lines, CM file must have exactly 1 CM in it";
      }
      if($ncksum_read > 1) { 
        if($cksum ne $tmp_cksum) { 
          die "ERROR, read two different CKSUM lines: $cksum and $tmp_cksum"; 
        }
      }
      $cksum = $tmp_cksum;
    }
  }
  close(CM);
  
  if(! defined $version)      { die "ERROR didn't read a version line in cm file $in_cmfile"; }
  if(! defined $cmbuild_opts) { die "ERROR didn't read a COM cmbuild line in cm file $in_cmfile"; }
  if(! defined $cksum)        { die "ERROR didn't read a CKSUM line in cm file $in_cmfile"; }

  return($cksum, $cmbuild_opts);
}

    
#################################################################
# Subroutine : strip_cmfile()
# Incept:      EPN, Mon Oct 15 06:18:08 2018
#
# Purpose:     Remove the following lines from CM file and
#              save the remaining lines to a new file.
#
# Arguments:   $in_cmfile:  name of cmfile to strip lines from
#              $out_cmfile: name of cmfile to create
# 
# Returns:     void
#
# Dies:        Never
#
################################################################# 
sub strip_cmfile { 
  my $nargs_expected = 2;
  my $sub_name = "strip_cmfile";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($in_cmfile, $out_cmfile) = (@_);

  open(IN,       $in_cmfile)  || die "ERROR unable to open $in_cmfile for reading";
  open(OUT, ">", $out_cmfile) || die "ERROR unable to open $out_cmfile for writing";
  while(my $line = <IN>) { 
    if($line =~ m/^COM/) { 
      ; # do nothing
    }
    elsif($line =~ m/^DATE/) { 
      ; # do nothing
    }
    elsif($line =~ m/^ECM/) { 
      ; # do nothing
    }
    elsif($line =~ m/^DESC/) { 
      ; # do nothing
    }
    else { 
      print OUT $line;
    }
  }
  close(IN);
  close(OUT);

  return;
}


#################################################################
# Subroutine : check_diff_output()
# Incept:      EPN, Mon Oct 15 09:11:03 2018
#
# Purpose:     Given diff output check if it is acceptable or not.
#              Floating point numbers are allowed to be different 
#              by 0.00001.
#
# Arguments:   $diff_output: string that is the diff output
#              $thresh:      maximum allowed difference between floating point parameters
#
# Returns:     Two values: 
#              $ndiff: number of different tokens between the two files
#              $err_str: error string to output describing why diff output is not acceptable
#              "" if diff output is acceptable
#
# Dies:        Never
#
################################################################# 
sub check_diff_output { 
  my $nargs_expected = 2;
  my $sub_name = "check_diff_output";
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($diff_output, $thresh) = (@_);

  my @line_A = split("\n", $diff_output);
  my @file1_A = (); # array of lines prefixed with "<" in diff output, from file 1
  my @file2_A = (); # array of lines prefixed with ">" in diff output, from file 2

  foreach my $line (@line_A) { 
    if($line =~ m/^</) { 
      chomp $line;
      push(@file1_A, $line);
    }
    elsif($line =~ m/^>/) { 
      chomp $line;
      push(@file2_A, $line);
    }
  }

  my $ndiff = 0;
  my $ret_str = "";

  # return immediately if different number of lines in each file
  if(scalar(@file1_A) != scalar(@file2_A)) { 
    return($ndiff, sprintf("Different number of lines in diff output from each file %d != %d\n", scalar(@file1_A), scalar(@file2_A)));
  }

  # for each line, make sure all tokens are either identical or numbers that differ by no more than $threshold
  my $nlines = scalar(@file1_A); 
  my ($i, $j);
  for($i = 0; $i < $nlines; $i++) { 
    my $line1 = $file1_A[$i];
    my $line2 = $file2_A[$i];
    my @el1_A = split(/\s+/, $line1);
    my @el2_A = split(/\s+/, $line2);
    my $nels = scalar(@el1_A); 
    if($nels != scalar(@el2_A)) { 
      $ret_str .= sprintf("Line %d differs in number of tokens:\n$line1\n$line2\n", $i+1, scalar(@el1_A), scalar(@el2_A));
    }
    for($j = 1; $j < $nels; $j++) { 
      my $el1 = $el1_A[$j];
      my $el2 = $el2_A[$j];
      if($el1 ne $el2) { 
        $ndiff++;
        if(($el1 =~ m/\d+\.\d+/) && ($el2 =~ m/\d+\.\d+/)) { 
          if(abs($el1-$el2) > $thresh) { 
            $ret_str .= sprintf("Line %d, token %d is numeric differs significantly (more than $thresh) $el1 != $el2\n$line1\n$line2\n\n", $i+1, $j+1, scalar(@el1_A), scalar(@el2_A));
          }
        }
        else { 
          $ret_str .= sprintf("Line %d, token %d is not numeric but differs $el1 != $el2\n$line1\n$line2\n\n", $i+1, $j+1, scalar(@el1_A), scalar(@el2_A));
        }
      }
    }
  }
        
  return ($ndiff, $ret_str);
}

