#!/usr/bin/env perl
# 
# tblout-add-tax-using-edirect.pl: add taxonomy information to hmmer or infernal tblout files using edirect tools
#                                  PROBABLY WILL ONLY WORK INTERNALLY AT NCBI
#
# EPN, Fri Feb 23 11:03:42 2018
# 
#
use strict;
use warnings;
use Getopt::Long;

my $tblout_file  = "";   # name of input tblout file

my $usage;
$usage  = "tblout-add-taxon-using-edirect.pl\n";
$usage .= "Usage:\n\n";
$usage .= "tblout-add-taxon-using-edirect.pl <tblout file (can't be streamed)>\n\tOR\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t-l <n>       : truncate taxonomy strings after <n> levels\n";
$usage .= "\t\t--cmscan     : tblout files are cmscan v1.1xoutput [default is to assume cmsearch v1.1x]\n";
$usage .= "\t\t--fmt2       : tblout files were created with cmsearch/cmscan v1.1x --fmt 2\n";
$usage .= "\t\t--nhmmer     : tblout files are from nhmmer v3.x\n";
$usage .= "\t\t--nhmmscan   : tblout files are from nhmmscan v3.x\n";
$usage .= "\t\t--hmmsearch  : tblout files are from hmmsearch v3.x\n";
$usage .= "\t\t--hmmscan    : tblout files are from hmmscan v3.x\n";
$usage .= "\t\t--dirty      : keep intermediate files that are otherwise removed\n\n";

my $do_cmsearch      = 1;     # set to '0' if any of --cmscan, --nhmmer, --nhmmscan, --hmmsearch, --hmmscan used
my $do_cmscan        = 0;     # set to '1' if --cmscan used, input tblout file(s) are from infernal 1.1x's cmscan
my $do_fmt2          = 0;     # set to '1' if --fmt2 used, input tblout file(s) used --fmt 2 from infernal 1.1x
my $do_nhmmer        = 0;     # set to '1' if --nhmmer used, input tblout file(s) are from hmmer3's nhmmer
my $do_nhmmscan      = 0;     # set to '1' if --nhmmscan used, input tblout file(s) are from hmmer3's nhmmscan
my $do_hmmsearch     = 0;     # set to '1' if --hmmsearch used, input tblout file(s) are from hmmer3's hmmsearch
my $do_hmmscan       = 0;     # set to '1' if --hmmscan used, input tblout file(s) are from hmmer3's hmmscan
my $do_dirty         = 0;     # set to '1' if --dirty used, keep intermediate files
my $tax_level        = -1;    # set to <n> if -l <n> used

&GetOptions( "l=s"       => \$tax_level,
             "cmscan"    => \$do_cmscan,
             "fmt2"      => \$do_fmt2,
             "nhmmer"    => \$do_nhmmer,
             "nhmmscan"  => \$do_nhmmscan,
             "hmmsearch" => \$do_hmmsearch,
             "hmmscan"   => \$do_hmmscan, 
             "dirty"     => \$do_dirty);

if(scalar(@ARGV) != 1) { die $usage; }
($tblout_file) = @ARGV;

if(($do_cmscan + $do_nhmmer + $do_nhmmscan + $do_hmmsearch + $do_hmmscan) > 1) { 
  die "ERROR, can only use one of --cmscan, --nhmmer, --nhmmscan, --hmmsearch, --hmmscan.";
}
if(($do_cmscan + $do_nhmmer + $do_nhmmscan + $do_hmmsearch + $do_hmmscan) == 1) { 
  $do_cmsearch = 0;
}

if(! -e $tblout_file) { die "ERROR tblout file $tblout_file does not exist"; }
if(! -s $tblout_file) { die "ERROR tblout file $tblout_file is empty"; }

# first pass through tblout file to get hash of all sequences that exist at least once so we can 
# use edirect to get their taxonomy strings
if($do_cmscan)    { die "ERROR --cmscan not yet implemented"; }
if($do_nhmmscan)  { die "ERROR --nhmmscan not yet implemented"; }
if($do_hmmscan)   { die "ERROR --hmmscan not yet implemented"; }
if($do_fmt2)      { die "ERROR --fmt2 not yet implemented"; }

my %target_H = ();

open(TBLOUT, $tblout_file) || die "ERROR unable to open $tblout_file for reading";
my $line;
while($line = <TBLOUT>) { 
  if($line !~ m/^\#/) { 
    chomp $line;

    my $target_name = undef;
    if($do_cmsearch) { 
      $target_name = parse_cmsearch_tblout_line($line);
    }
    elsif($do_nhmmer) { 
      $target_name = parse_nhmmer_tblout_line($line);
    }
    elsif($do_hmmsearch) { 
      $target_name = parse_hmmsearch_tblout_line($line);
    }
    my $deversioned_target_name = deversion_accession_version($target_name);
    $target_H{$deversioned_target_name} = 1;
  }
}

# make the input file for edirect:
my $tmp_edirect_in  = "$$.tmp.edirect.in";
my $tmp_edirect_out = "$$.tmp.edirect.out";
open(TMP, ">", $tmp_edirect_in) || die "ERROR unable to open tmp.edirect.in for writing"; 
foreach my $key (sort keys (%target_H)) { 
  print TMP $key . "\n";
}
close(TMP);

# run edirect
my $db = ($do_hmmsearch || $do_hmmscan) ? "protein" : "nuccore";
run_command("cat $tmp_edirect_in | epost -db $db -format acc | efetch -format gpc | xtract -insd INSDSeq_taxonomy | grep . | sort > $tmp_edirect_out", 0);

# parse the edirect output
open(EDIRECT, $tmp_edirect_out) || die "ERROR unable to open $tmp_edirect_out for reading";
my %taxstring_H = ();
my $max_tax_string_len = 0;
while($line = <EDIRECT>) { 
  if($line !~ m/^\#/) { 
    my @el_A = split(/\t+/, $line);
    if(scalar(@el_A) != 2) { die "ERROR didn't read 2 tokens in edirect output line $line"; }
    my ($accver, $taxstring) = split(/\t/, $line);
    my $acc = deversion_accession_version($accver);
    $taxstring =~ s/\s+//g; # remove whitespace

    # shorten tax string if nec
    if($tax_level != -1) { 
      my @tax_A = split(";", $taxstring);
      $taxstring = "";
      for(my $i = 0; $i < $tax_level; $i++) { 
        $taxstring .= $tax_A[$i] . ";";
      }
    }

    $taxstring_H{$acc} = $taxstring;
    if(length($taxstring) > $max_tax_string_len) { 
      $max_tax_string_len = length($taxstring);
    }
  }
}
close(EDIRECT);

# second pass through the tblout file, add the taxstring as the first token
open(TBLOUT, $tblout_file) || die "ERROR unable to open $tblout_file for reading";
while($line = <TBLOUT>) { 
  if($line !~ m/^\#/) { 
    chomp $line;

    my $target_name = undef;
    if($do_cmsearch) { 
      $target_name = parse_cmsearch_tblout_line($line);
    }
    elsif($do_nhmmer) { 
      $target_name = parse_nhmmer_tblout_line($line);
    }
    elsif($do_hmmsearch) { 
      $target_name = parse_hmmsearch_tblout_line($line);
    }
    my $deversioned_target_name = deversion_accession_version($target_name);
    if(exists $taxstring_H{$deversioned_target_name}) { 
      printf("%-*s %s\n", $max_tax_string_len, $taxstring_H{$deversioned_target_name}, $line);
    }
    else { 
      printf("%-*s %s\n", $max_tax_string_len, "-", $line);
    }
  }
  else { 
    print $line; 
  }
}
close(TBLOUT);
#################################################################
# Subroutine:  deversion_accession_version()
# Incept:      EPN, Fri Feb 23 11:30:19 2018
#
# Purpose:     Removes version from "accession.version" string.
#
# Arguments:
#   $accver:      accession version string to deversion
#
# Returns:    string that is just accession 
#
# Dies:       if accession version string is not in expected format
#################################################################
sub deversion_accession_version { 
  my $sub_name = "deversion_accession_version";
  my $nargs_expected = 1;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($accver) = @_;
  
  if($accver =~ /(\S+)\.\d+/) { 
    return $1;
  }
  else { 
    die "ERROR in $sub_name, $accver did not match \\S+\\.\\d+";
  }
  return ""; # NOTREACHED
}
  

#################################################################
# Subroutine:  run_command()
# Incept:      EPN, Mon Dec 19 10:43:45 2016
#
# Purpose:     Runs a command using system() and exits in error 
#              if the command fails. If $be_verbose, outputs
#              the command to stdout. 
#
# Arguments:
#   $cmd:         command to run, with a "system" command;
#   $be_verbose:  '1' to output command to stdout before we run it, '0' not to
#
# Returns:    nothing
#
# Dies:       if $cmd fails
#################################################################
sub run_command {
  my $sub_name = "run_command()";
  my $nargs_expected = 2;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($cmd, $be_verbose) = @_;
  
  if($be_verbose) { 
    print ("Running cmd: $cmd\n"); 
  }

  system($cmd);

  if($? != 0) { 
    die "ERROR in $sub_name, the following command failed:\n$cmd\n";
  }

  return;
}

#################################################################
# Subroutine:  parse_cmsearch_tblout_line()
# Incept:      EPN, Fri Dec  8 09:33:23 2017
#
# Purpose:     Given an infernal cmsearch --tblout line, 
#              return $target, $query, $seqfrom, $seqto, $strand, $score, $evalue.
#
#     # Example line
#     #target name         accession query name           accession mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc description of target
#     #------------------- --------- -------------------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- ---------------------
#     5S_rRNA-sample10     -         5S_rRNA              RF00001    cm        1      119        1      121      +    no    1 0.61   0.0  108.2   1.5e-27 !   -
#
# Arguments:
#   $line:  line to parse
#
# Returns:    $target: name of target       (5S_rRNA-sample10)
#
# Dies:       if line has fewer than 18 space delimited characters
#################################################################
sub parse_cmsearch_tblout_line { 
  my $sub_name = "parse_cmsearch_tblout_line";
  my $nargs_expected = 1;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($line) = @_;
  
  my @el_A = split(/\s+/, $line);

  if(scalar(@el_A) < 18) { die "ERROR found less than 18 columns in cmsearch tabular output at line: $line"; }
#    ($target, $query, $mdlfrom, $mdlto, $seqfrom, $seqto, $strand, $score, $evalue) = 
  my ($target, $query, $seqfrom, $seqto, $strand, $score, $evalue) = 
      ($el_A[0], $el_A[2], $el_A[7], $el_A[8], $el_A[9],  $el_A[14], $el_A[15]);

  return($target);
}

#################################################################
# Subroutine:  parse_nhmmer_tblout_line()
# Incept:      EPN, Fri Dec  8 09:42:28 2017
#
# Purpose:     Given an nhmmer --tblout line, 
#              return $target, $query, $seqfrom, $seqto, $strand, $score, $evalue.
#
#     # Example line
#     # target name        accession  query name           accession  hmmfrom hmm to alifrom  ali to envfrom  env to  sq len strand   E-value  score  bias  description of target
#     #------------------- ---------- -------------------- ---------- ------- ------- ------- ------- ------- ------- ------- ------ --------- ------ ----- ---------------------
#     5S_rRNA-sample10     -          5S_rRNA              RF00001          4     115       4     117       1     121     121    +     1.6e-17   53.3   4.8  -
#
# Arguments:
#   $line:  line to parse
#
# Returns:    $target: name of target       (5S_rRNA-sample10)
#             $query:  query name           (5S_rRNA)
#             $seqfrom: ali from coord      (4)
#             $seqto:   ali to coord        (117)
#             $strand:  strand of hit       (+)
#             $score:   bit score of hit    (53.3)
#             $evalue:  E-value of hit      (1.6e-17)
#
# Dies:       if line has fewer than 16 space delimited characters
#################################################################
sub parse_nhmmer_tblout_line { 
  my $sub_name = "parse_nhmmer_tblout_line";
  my $nargs_expected = 1;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($line) = @_;
  
  my @el_A = split(/\s+/, $line);

  if(scalar(@el_A) < 16) { die "ERROR found less than 16 columns in nhmmer tabular output at line: $line"; }
  my ($target, $query, $seqfrom, $seqto, $strand, $evalue, $score) = 
      ($el_A[0], $el_A[2], $el_A[6], $el_A[7], $el_A[11], $el_A[12], $el_A[13]);

  return($target);
}

#################################################################
# Subroutine:  parse_hmmsearch_tblout_line()
# Incept:      EPN, Fri Dec  8 09:47:19 2017
#
# Purpose:     Given an hmmsearch --tblout line, 
#              return $target, $query, $score, $evalue.
#
#     # Example line
#     #                                                               --- full sequence ---- --- best 1 domain ---- --- domain number estimation ----
#     # target name        accession  query name           accession    E-value  score  bias   E-value  score  bias   exp reg clu  ov env dom rep inc description of target
#     #------------------- ---------- -------------------- ---------- --------- ------ ----- --------- ------ -----   --- --- --- --- --- --- --- --- ---------------------
#     5S_rRNA-sample10     -          5S_rRNA              RF00001      1.1e-19   59.8   0.0   1.2e-19   59.7   0.0   1.0   1   0   0   1   1   1   1 -
#
# Arguments:
#   $line:             line to parse
#
# Returns:    $target: name of target       (5S_rRNA-sample10)
#             $query:  query name           (5S_rRNA)
#             $score:  bit score of sequence  (53.3)
#             $evalue: E-value of hit      (1.6e-17)
#
# Dies:       if line has fewer than 19 space delimited characters
#################################################################
sub parse_hmmsearch_tblout_line { 
  my $sub_name = "parse_hmmsearch_tblout_line";
  my $nargs_expected = 1;
  if(scalar(@_) != $nargs_expected) { printf STDERR ("ERROR, $sub_name entered with %d != %d input arguments.\n", scalar(@_), $nargs_expected); exit(1); } 

  my ($line) = @_;
  
  my @el_A = split(/\s+/, $line);

  if(scalar(@el_A) < 19) { die "ERROR found less than 16 columns in nhmmer tabular output at line: $line"; }
  my ($target, $query, $full_evalue, $full_score, $best_evalue, $best_score) = 
      ($el_A[0], $el_A[2], $el_A[4], $el_A[5], $el_A[7], $el_A[8]);

  return ($target);
}
