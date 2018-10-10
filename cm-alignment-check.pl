use strict;
use warnings;
use Getopt::Long;

my $usage;
$usage = "cm-alignment-check.pl\n\n";
$usage .= "Usage:\n\n";
$usage .= "cm-alignment-check.pl <Infernal v1.1x CM file> <stockholm alignment to check if it was used with cmbuild to create the CM>\n";

if(scalar(@ARGV) != 2) { die $usage; }
my ($in_cmfile, $in_alnfile) = @ARGV;

# parse cm file
my ($in_cksum, $in_cmbuild_opts) = parse_cmfile($in_cmfile);

# build temporary CM
if($in_cmbuild_opts !~ m/-F\s+/) { 
  $in_cmbuild_opts .= " -F ";
}
system("cmbuild $in_cmbuild_opts tmp.cm $in_alnfile > /dev/null");
if($? != 0) { 
  die "ERROR, unable to build temporary CM file tmp.cm";
}

# parse temporary CM
my ($tmp_cksum, undef) = parse_cmfile("tmp.cm");

# diff the files
my $diff_output = `diff $in_cmfile tmp.cm`;

if($in_cksum eq $tmp_cksum) { 
  printf("CHECKSUM match $in_cksum\n");
}
else { 
  printf("CHECKSUM mismatch $in_cksum != $tmp_cksum\n");
}

if($diff_output eq "") { 
  printf("diff is clean, CM files identical");
}
else { 
  printf("diff is not clean:\n$diff_output\n");
}

exit 0;
    
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
    elsif($line =~ m/^COM\s+\[\d+]\s+.+(cmbuild.+)$/) {
      # parse out cmbuild options used
      $ncmbuild_read++;
      if($ncmbuild_read > 2) { 
        die "ERROR read more than two COM cmbuild lines, CM file must have exactly 1 CM in it";
      }
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
  
  if(! defined $version)      { die "ERROR didn't read a version line in cm file"; }
  if(! defined $cmbuild_opts) { die "ERROR didn't read a COM cmbuild line in cm file"; }
  if(! defined $cksum)        { die "ERROR didn't read a CKSUM line in cm file"; }

  return($cksum, $cmbuild_opts);
}
