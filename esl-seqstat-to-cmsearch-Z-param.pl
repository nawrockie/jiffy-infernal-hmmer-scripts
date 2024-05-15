#!/usr/bin/env perl
# 
# esl-seqstat-to-cmsearch-Z-param.pl: determine the appropriate -Z value for cmsearch for a given database
#                                     given one or more esl-seqstat output files for the sequence files that
#                                     make up that database.
#                        
# EPN, Mon May 13 10:55:31 2024
# 
use strict;
use warnings;
use Getopt::Long;

my $usage;
$usage  = "esl-seqstat-to-cmsearch-Z-param.pl\n\n";
$usage .= "Usage:\n";
$usage .= "\tesl-seqstat-to-cmsearch-Z-param.pl [OPTIONS]\n";
$usage .= "\t<list of esl-seqstat output files>\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t-i          : input argument is a single esl-seqstat output file, not a list\n";
$usage .= "\n";

my $do_indi = 0;   # set to '1' if -i used
&GetOptions( "i" => \$do_indi);

if(scalar(@ARGV) != 1) { die $usage; }
my ($in_file) = (@ARGV);

# get the array of sequence files
my @seqstat_A = ();
if($do_indi) {
  push(@seqstat_A, $in_file);
}
else {
  open(IN, $in_file) || die "ERROR unable to open $in_file for reading";
  while(my $line = <IN>) {
    chomp $line;
    push(@seqstat_A, $line);
  }
  close(IN);
}

my $total_nres = 0;
my $nfiles = 0;
foreach my $seqstat_file (@seqstat_A) {
  $nfiles++;
  my $nres_seen = 0;
  open(IN, $seqstat_file) || die "ERROR unable to open $seqstat_file for reading";
  while(my $line = <IN>) {
    if($line =~ /^Total \# residues\:\s+(\d+)/) {
      $total_nres += $1;
      $nres_seen = 1;
    }
  }
  close(IN);
  if(! $nres_seen) {
    die "ERROR did not read num residues line for file $seqstat_file";
  }
}

printf("Read %d seqstat files, total number residues: %d\n", $nfiles, $total_nres);
printf("cmsearch -Z value (both strands, in Mb): %.5f\n", ($total_nres * 2) / 1000000.);


