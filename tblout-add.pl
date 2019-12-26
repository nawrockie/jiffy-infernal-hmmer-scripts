#!/usr/bin/env perl
# 
# tblout-add.pl: add a field to a tblout file
#                        
# EPN, Thu Dec 26 06:26:06 2019
# 
use strict;
use warnings;
use Getopt::Long;

my $usage;
$usage  = "tblout-add.pl\n\n";
$usage .= "Usage:\n";
$usage .= "\ttblout-add.pl [OPTIONS]\n";
$usage .= "\t<tblout file to add to>\n";
$usage .= "\t<nexp, number of expected fields (last 'field' may contain whitespace)>\n";
$usage .= "\t<add file with data to add, two fields per line>\n";
$usage .= "\t<field number [1..nexp] in tblout file that field 1 of add file pertains to>\n\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t-t          : make output tab delimited\n";
$usage .= "\t\t--empty <s> : specify empty value for new field be <s> [default: '-']\n";
$usage .= "\n";

my $do_tab    = 0;   # set to '1' if -t used
my $add_empty = "-"; # set to <s> if --empty <s>used
&GetOptions( "t"       => \$do_tab,
             "empty=s" => \$add_empty);

if(scalar(@ARGV) != 4) { die $usage; }
my ($in_tblout, $in_nexp, $in_add, $in_field) = @ARGV;

if(($in_field < 1) || ($in_field >= $in_nexp)) { 
  die "ERROR cmdline argument 4 must be between 1 and <nexp>-1, where <nexp> is cmdline argument 1";
}
if(! -e $in_tblout) { die "ERROR tblout file $in_tblout does not exist"; }
if(! -s $in_tblout) { die "ERROR tblout file $in_tblout is empty"; }
if(! -e $in_add)    { die "ERROR add file $in_add does not exist"; }
if(! -s $in_add)    { die "ERROR add file $in_add is empty"; }


my $line;
my $i;
open(ADD, $in_add) || die "ERROR unable to open $in_add for reading"; 
my %add_H = (); # key is 1st field from line in $in_add, value is 2nd field
my $add_w = length($add_empty); # max length of any value
while($line = <ADD>) { 
  my @el_A = split(/\s+/, $line);
  my ($key, $value) = ($el_A[0], $el_A[1]); 
  if(defined $add_H{$key}) { 
    die "ERROR read two lines with key $key in add file $in_add\n"; 
  }
  $add_H{$key} = $value;
  if(length($value) > $add_w) { 
    $add_w = length($value);
  }
}

open(TBLOUT, $in_tblout) || die "ERROR unable to open $in_tblout for reading"; 
while($line = <TBLOUT>) { 
  if($line !~ m/^\#/) { 
    if($line =~ m/^\s+/) { 
      die "ERROR data line starts with whitespace:\n$line\n"; 
    }
    chomp $line;
    my @el_A = split(/\s+/, $line);
    my $nfields = scalar(@el_A);
    if($nfields < $in_nexp) { 
      die "ERROR expected at least $in_nexp fields in each line, got $nfields on line $line\n";
    }

    # get fields with spacing
    my $rem_line = $line;
    my @el_w_space_A = (); # elements with proper spacing
    for($i = 0; $i < ($in_nexp-1); $i++) { 
      if($rem_line =~ s/(^\S+\s+)//) {
        push(@el_w_space_A, $1);
        #printf("pushed $1 to el_w_space_A\n");
      }
    }
    # push final 'field'
    #printf("pushed $rem_line to el_w_space_A\n");
    push(@el_w_space_A, $rem_line);

    # output
    # first nfields-1 fields
    for($i = 0; $i < ($in_nexp-1); $i++) { 
      if($do_tab) { print $el_A[$i] . "\t"; }
      else        { print $el_w_space_A[$i];  }
    }

    # field to add 
    my $add_field = $add_H{$el_A[($in_field-1)]};
    if(! defined $add_field) { $add_field = $add_empty; }
    if($do_tab) { print $add_field . "\t"; }
    else        { printf("%*s ", $add_w, $add_field); }

    # final field, same regardless of $do_tab value
    print $el_w_space_A[($in_nexp-1)];
    print "\n";
  }
}
