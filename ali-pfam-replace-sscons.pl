#!/usr/bin/env perl
# EPN, Wed Feb 11 2:44pm 2026
#
# Given a pfam formatted alignment with existing SS_cons annotation, replace that
# SS_cons annotation with a string read from another file, of same SS_cons length.
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "ali-pfam-replace-sscons.pl\n\n";
$usage .= "Usage:\n\n";
$usage .= "perl ali-pfam-replace-sscons.pl\n\t";
$usage .= "<pfam formatted alignment file with sscons annotation to replace>\n\t";
$usage .= "<file with one line that is sscons to add, of length equal to nongap sscons length of alignment>\n\n";

#&GetOptions( "a"  => \$opt_a);

if(scalar(@ARGV) != 2) { die $usage; }

my ($alifile, $sscons_file) = (@ARGV);

my %seen_H = ();  # key is sequence name, used to check to make sure we are in Pfam format

# open and read SS_cons
open(SSCONS, $sscons_file) || die "ERROR unable to open $sscons_file for reading";
my $in_sscons = <SSCONS>;
chomp $in_sscons;
close(SSCONS);

# 
open(ALI, $alifile) || die "ERROR unable to open $alifile"; 
# first pass to determine sscons_nongap columns
my $found_sscons = 0;
my $i;
my @sscons_nongap_A = ();
my $line;
my $ssconslen = 0;
my $ssconsspacelen = 0; # length of space between "sscons" and start of sscons annotation in "#=GC sscons   ..." line
my $alen = 0;
while($line = <ALI>) { 
  if($line =~ /^\#=GC\s+SS_cons(\s+)(\S+)$/) { 
    $ssconsspacelen = length($1);
    my $sscons = $2;
    my @sscons_A = split("", $sscons);
    $alen = scalar(@sscons_A);

    if($found_sscons) { 
      die "ERROR sscons line found twice, did you convert to pfam format (e.g. esl-reformat pfam ...)?";
    }
    for($i = 0; $i < scalar(@sscons_A); $i++) { 
      if($sscons_A[$i] =~ m/[\.\~]/) { 
        # gap
        $sscons_nongap_A[$i] = 0;
      }
      else { 
        # nongap
        $sscons_nongap_A[$i] = 1;
        $ssconslen++;
      }
    }
    $found_sscons = 1;
  }
  elsif($line =~ /^(\S+)(\s+)(\S+)$/) { 
    my ($seqname, $space, $seq) = ($1, $2, $3);
    if((exists $seen_H{$seqname}) && ($seen_H{$seqname} == 1)) { 
      die "ERROR saw sequence $seqname twice, did you convert to pfam format (e.g. esl-reformat pfam ...)?";
    }
    $seen_H{$seqname} = 1;
  }
}
if(! $found_sscons) { die "ERROR did not find sscons annotation in $alifile"; }
close(ALI);

if($ssconslen != length($in_sscons)) { 
  die sprintf("ERROR nongap sscons length read from $alifile is $ssconslen, this should match length of first line of the sscons annotation $sscons_file, but it does not (that value is %d)\n", length($in_sscons));
}

# create gapped out new sscons line
my @in_sscons_A = split("", $in_sscons);
my $sscons_prefix = "#=GC SS_cons";
for($i = 0; $i < $ssconsspacelen; $i++) { 
  $sscons_prefix .= " ";
}
my $new_sscons_line = "";
my $ssconspos = 0;
for($i = 0; $i < $alen; $i++) { 
  if($sscons_nongap_A[$i]) { 
    $new_sscons_line .= $in_sscons_A[$ssconspos];
    $ssconspos++;
  }
  else { 
    $new_sscons_line .= ".";
  }
}
if(length($new_sscons_line) != $alen) { 
  die "ERROR problem creating new sscons line lengths don't match";
}
if($ssconspos != $ssconslen) { 
  die "ERROR problem creating new sscons, lengths don't match";
}
$new_sscons_line = $sscons_prefix . $new_sscons_line;
  
# second pass to add sscons
open(ALI, $alifile) || die "ERROR unable to open $alifile on second pass"; 
while($line = <ALI>) { 
  if($line =~ /^\#=GC\s+SS_cons\s+/) { 
    print $new_sscons_line . "\n";
  }
  else { 
    print $line;
  }
}
close(ALI);

