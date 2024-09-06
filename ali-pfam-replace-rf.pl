#!/usr/bin/env perl
# EPN, Fri Sep  6 14:00:10 2024
#
# Given a pfam formatted alignment with existing RF annotation, replace that
# RF annotation with a string read from another file, of same RF length.
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "ali-pfam-replace-rf.pl\n\n";
$usage .= "Usage:\n\n";
$usage .= "perl ali-pfam-replace-rf.pl\n\t";
$usage .= "<pfam formatted alignment file with RF annotation to replace>\n\t";
$usage .= "<file with one line that is RF to add, of length equal to nongap RF length of alignment>\n\n";

#&GetOptions( "a"  => \$opt_a);

if(scalar(@ARGV) != 2) { die $usage; }

my ($alifile, $rf_file) = (@ARGV);

my %seen_H = ();  # key is sequence name, used to check to make sure we are in Pfam format

# open and read SS_cons
open(RF, $rf_file) || die "ERROR unable to open $rf_file for reading";
my $in_rf = <RF>;
chomp $in_rf;
close(RF);

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

if($rflen != length($in_rf)) { 
  die sprintf("ERROR nongap RF length read from $alifile is $rflen, this should match length of first line of the RF annotation $rf_file, but it does not (that value is %d)\n", length($in_rf));
}

# create gapped out new RF line
my @in_rf_A = split("", $in_rf);
my $rf_prefix = "#=GC RF";
for($i = 0; $i < $rfspacelen; $i++) { 
  $rf_prefix .= " ";
}
my $new_rf_line = "";
my $rfpos = 0;
for($i = 0; $i < $alen; $i++) { 
  if($rf_nongap_A[$i]) { 
    $new_rf_line .= $in_rf_A[$rfpos];
    $rfpos++;
  }
  else { 
    $new_rf_line .= ".";
  }
}
if(length($new_rf_line) != $alen) { 
  die "ERROR problem creating new RF line lengths don't match";
}
if($rfpos != $rflen) { 
  die "ERROR problem creating new RF, lengths don't match";
}
$new_rf_line = $rf_prefix . $new_rf_line;
  
# second pass to add RF
open(ALI, $alifile) || die "ERROR unable to open $alifile on second pass"; 
while($line = <ALI>) { 
  if($line =~ /^\#=GC\s+RF/) { 
    print $new_rf_line . "\n";
  }
  else { 
    print $line;
  }
}
close(ALI);

