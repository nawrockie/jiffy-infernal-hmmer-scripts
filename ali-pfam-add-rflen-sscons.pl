#!/usr/bin/env perl
# EPN, Wed Sep 16 12:00:25 2020
# ali-pfam-add-sscons.pl
#
# Given a pfam formatted alignment (1) with RF annotation, and another alignment (2) with 
# the same number of nongap RF columns, add SS_cons from alignment (2) to alignment (1).
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "ali-pfam-add-rflen-sscons.pl\n\n";
$usage .= "Usage:\n\n";
$usage .= "perl ali-pfam-add-rflen-sscons.pl\n\t";
$usage .= "<pfam formatted alignment file to add SS_cons to>\n\t";
$usage .= "<file with one line that is SS_cons to add, of length equal to nongap RF length of alignment>\n\n";
$usage .= "Usage starting from two Stockholm alignment files, to add SS_cons from ali 2 to ali 1:\n\t";
$usage .= "esl-reformat pfam ali1.sto > ali1.pfam\n\t";
$usage .= "esl-alimask --rf-is-mask ali2.sto | esl-reformat pfam - | grep \"^\\#=GC SS_cons\" | awk '{ print \$3 }' > ali2.sscons.txt\n\t";
$usage .= "perl ali-pfam-add-rflen-sscons.pl ali1.pfam ali2.sscons.txt > ali1.sscons.pfam\n\t";
$usage .= "esl-reformat stockholm ali1.sscons.pfam > ali1.sscons.sto\n\n";



#&GetOptions( "a"  => \$opt_a);

if(scalar(@ARGV) != 2) { die $usage; }

my ($alifile, $sscons_file) = (@ARGV);

my %seen_H = ();    # key is sequence name, used to check to make sure we are in Pfam format

# open and read SS_cons
open(SSCONS, $sscons_file) || die "ERROR unable to open $sscons_file for reading";
my $sscons = <SSCONS>;
chomp $sscons;
close(SSCONS);

# 
open(ALI, $alifile) || die "ERROR unable to open $alifile"; 
# first pass to determine rf_nongap columns
my $found_rf = 0;
my $i;
my @rf_nongap_A = ();
my $line;
my $rflen = 0;
my $rfspacelen = 0; # length of space between "RF" and start of RF annotation in "#=GC RF   ..." line
my $alen = 0;
while($line = <ALI>) { 
  if($line =~ /^\#=GC\s+RF(\s+)(\S+)$/) { 
    $rfspacelen = length($1);
    my $rf = $2;
    my @rf_A = split("", $rf);
    $alen = scalar(@rf_A);

    if($found_rf) { 
      die "ERROR RF line found twice, did you convert to pfam format (e.g. esl-reformat pfam ...)?";
    }
    for($i = 0; $i < scalar(@rf_A); $i++) { 
      if($rf_A[$i] =~ m/[\.\-\~]/) { 
        # gap
        $rf_nongap_A[$i] = 0;
      }
      else { 
        # nongap
        $rf_nongap_A[$i] = 1;
        $rflen++;
      }
    }
    $found_rf = 1;
  }
  elsif($line =~ /^\#=GC\s+SS_cons\s+(\S+)$/) { 
    die "ERROR found SS_cons in $alifile, remove it and try again";
  }
  elsif($line =~ /^(\S+)(\s+)(\S+)$/) { 
    my ($seqname, $space, $seq) = ($1, $2, $3);
    if((exists $seen_H{$seqname}) && ($seen_H{$seqname} == 1)) { 
      die "ERROR saw sequence $seqname twice, did you convert to pfam format (e.g. esl-reformat pfam ...)?";
    }
    $seen_H{$seqname} = 1;
  }
}
if(! $found_rf) { die "ERROR did not find RF annotation in $alifile"; }
close(ALI);

if($rflen != length($sscons)) { 
  die sprintf("ERROR nongap RF length read from $alifile is $rflen, this should match length of first line of SS_cons in $sscons_file, but it does not (that value is %d)\n", length($sscons));
}

# create gapped out SS_cons line
my @sscons_A = split("", $sscons);
my $sscons_prefix = "#=GC SS_cons";
for($i = 0; $i < $rfspacelen; $i++) { 
  $sscons_prefix .= " ";
}
my $sscons_line = "";
my $rfpos = 0;
for($i = 0; $i < $alen; $i++) { 
  if($rf_nongap_A[$i]) { 
    $sscons_line .= $sscons_A[$rfpos];
    $rfpos++;
  }
  else { 
    $sscons_line .= ".";
  }
}
if(length($sscons_line) != $alen) { 
  die "ERROR problem creating sscons_line lengths don't match";
}
if($rfpos != $rflen) { 
  die "ERROR problem creating sscons_line RF lengths don't match";
}
$sscons_line = $sscons_prefix . $sscons_line;
  
# second pass to add SS_cons
open(ALI, $alifile) || die "ERROR unable to open $alifile on second pass"; 
while($line = <ALI>) { 
  if($line =~ /^\#=GC\s+RF/) { 
    # print SS_cons just before RF line
    print $sscons_line . "\n";
  }
  print $line; 
}
close(ALI);

