#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;

my $usage = "perl cmsearch-tblout-prune-mdlfract.pl <Infernal v1.1x tblout file> <model length file with two tokens per line: <mdlname> <mdllen>> <min model fraction to keep>\n";
$usage .= "\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t-e <s> : set max E-value to keep as <s>\n";
$usage .= "\t\t-t <s> : set min bit score to keep as <s>\n";
$usage .= "\n";
$usage .= "to make model length file: cmstat <cmfile> | grep -v ^\#  | awk '{ printf(\"\%s \%s\\n\", \$2, \$6); }'\n";
$usage .= "\n";

my $do_e = 0;   # set to '1' if -e used
my $do_t = 0;   # set to '1' if -t used
my $ecut = undef;
my $tcut = undef;
&GetOptions( "e=s" => \$ecut,
             "t=s" => \$tcut);

if(defined $ecut) { $do_e = 1; };
if(defined $tcut) { $do_t = 1; };

if(scalar(@ARGV) != 3) { die $usage; }

my ($tblout_file, $mdllen_file, $fractthresh) = (@ARGV);

open(MDLLEN, $mdllen_file) || die "ERROR unable to open $mdllen_file for reading";
my %mdllen_H = ();
while(my $line = <MDLLEN>) { 
  chomp $line;
  my @el_A = split(/\s+/, $line);
  if(scalar(@el_A) != 2) { die "ERROR unable to parse $mdllen_file line $line\n"; }
  my ($mdlname, $mdllen) = (@el_A);
  $mdllen_H{$mdlname} = $mdllen;
}
close(MDLLEN);

open(TBLOUT, $tblout_file) || die "ERROR unable to open $tblout_file";
while(my $line = <TBLOUT>) { 
  chomp $line;
  if($line !~ m/^\#/) { 
##target name         accession query name           accession mdl mdl from   mdl to seq from   seq to strand trunc pass   gc  bias  score   E-value inc description of target
##------------------- --------- -------------------- --------- --- -------- -------- -------- -------- ------ ----- ---- ---- ----- ------ --------- --- ---------------------
#gi|255927625|gb|GQ303260.1| -         sim.all.YrlA.396.2   -   cm        1      105   128177   128297      +    no    1 0.58   0.0   32.1   0.00015 !   Mycobacterium phage ET08, complete genome
    my @el_A = split(/\s+/, $line);
    if(scalar(@el_A) < 18) { die "ERROR less than 18 tokens on line $line"; }
    my ($mdlname, $mdlfrom, $mdlto, $bitsc, $evalue) = ($el_A[2], $el_A[5], $el_A[6], $el_A[14], $el_A[15]);
    if(! defined $mdllen_H{$mdlname}) { die "ERROR read model $mdlname in tblout file not listed in $mdllen_file on line:$line"; }
    my $mdlspan = ($mdlto - $mdlfrom) + 1;
    my $mdlfract = $mdlspan / $mdllen_H{$mdlname};
    if($mdlfract >= $fractthresh) { 
      if(((! $do_t) || ($bitsc  >= $tcut)) && 
         ((! $do_e) || ($evalue <= $ecut))) { 
        print $line . "\n"; 
      }
    }
  }
}

    
