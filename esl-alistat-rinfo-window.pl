#!/usr/bin/env perl
# EPN, Fri May 25 12:55:03 2018
# esl-alistat-rinfo-window.pl
# Process esl-alistat --rinfo output to summarize number of gap columns in an alignment.
#
use warnings;
use strict;
use Getopt::Long;

my $do_fwd    = 1; # set to '0' if -3
my $n         = 100; # set to -n arg if -n used
my $gapthresh = 0.5; 
my $do_highlight = 0;
my $hthresh = undef;

my $usage;
$usage  = "perl esl-alistat-rinfo-window.pl [OPTIONS] <esl-alistat --rinfo output>\n\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t-n <n>: set window size to <n> positions [df: $n]\n";
$usage .= "\t\t-g <f>: set gap threshold to <f> [df: $gapthresh]\n";
$usage .= "\t\t-3:     go from 3' end backwards [df: 5' end forwards]\n";
$usage .= "\t\t-h <f>: highlight first position that has freq gap cols <= <f>\n";

my $opt_n  = undef;
my $opt_g  = undef;
my $opt_3  = undef;
my $opt_h  = undef;
&GetOptions( "3"   => \$opt_3,
             "g=s" => \$opt_g,
             "h=s" => \$opt_h,
             "n=s" => \$opt_n);

if(defined $opt_3) { $do_fwd = 0; }
if(defined $opt_n) { $n = $opt_n; }
if(defined $opt_h) { $do_highlight = 1; $hthresh = $opt_h; } 

if(scalar(@ARGV) != 1) { die $usage; }

my ($in_file) = (@ARGV);

##   rfpos   alnpos      numres   freqres      numgap   freqgap
## -------  -------  ----------  --------  ----------  --------
#        1        1         1.0  0.050000        19.0  0.950000

my @rfpos_A   = ();
my @apos_A    = ();
my @numres_A  = ();
my @freqres_A = ();
my @numgap_A  = ();
my @freqgap_A = ();

# first read entire file and store all info
my $done_highlight = 0;
my @info_A = ();
open(IN, $in_file) || die "ERROR unable to open $in_file for reading";
while(my $line = <IN>) { 
  if(($line !~ m/^\#/) && ($line !~ m/^\/\//)) { 
    chomp $line;
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    my @el_A = split(/\s+/, $line);
    if(scalar(@el_A) != 6) { die "ERROR did not read exactly 6 tokens on line $line"; }
    push (@rfpos_A,   $el_A[0]);
    push (@apos_A,    $el_A[1]);
    push (@numres_A,  $el_A[2]);
    push (@freqres_A, $el_A[3]);
    push (@numgap_A,  $el_A[4]);
    push (@freqgap_A, $el_A[5]);
  }
}
close(IN);
my $alen = scalar(@rfpos_A);

my $gap_in_window = 0;
for(my $i = 0; $i < $alen; $i++) { 
  my $orig_i = $i;
  if(! $do_fwd) { $i = ($alen - $i) - 1; }
  my $i_is_gap  = ($freqgap_A[$i] >= $gapthresh) ? 1 : 0;
  #printf("i: $i $freqgap_A[$i] i_is_gap: $i_is_gap\n");
  if($i_is_gap) { $gap_in_window++; }
  if(((  $do_fwd) && ($i >= $n)) || 
     ((! $do_fwd) && ($i <= ($alen-$n)))) { 
    my $oi = ($do_fwd) ? $i-$n : ($i+$n-1);
    my $oi_is_gap = ($freqgap_A[$oi] >= $gapthresh) ? 1 : 0;
    if($oi_is_gap) { $gap_in_window--; }
    my $hchar = "";
    if(($do_highlight) && (! $done_highlight) && (($gap_in_window/$n) <= $hthresh)) { 
      $hchar = "*";
      $done_highlight = 1;
    }
    printf("%swindow: %5d to %5d  alilen: %5d  ngapcol: %5d  fgapcol: %.3f\n", $hchar, $oi+1, $i+1, $alen, $gap_in_window, $gap_in_window / $n); 
  }
  $i = $orig_i;
}
