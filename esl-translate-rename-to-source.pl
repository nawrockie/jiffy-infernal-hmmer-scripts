#!/usr/bin/env perl
use strict;
use Getopt::Long;

my $usage = "esl-translate-rename-to-source.pl: rename sequences output from esl-translate\n";
$usage = "USAGE:\nperl esl-translate-longest-orf.pl <esl-translate output file>";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t-o: include orf name in new name\n";
$usage .= "\t\t-l: include length in new name\n";
$usage .= "\t\t-f: include frame in new name\n";

my $do_orf    = 0;
my $do_length = 0;
my $do_frame  = 0;
&GetOptions( "o" => \$do_orf, 
             "l" => \$do_length, 
             "f" => \$do_frame);

if(scalar(@ARGV) != 1) { die $usage; }
my ($in_file) = (@ARGV);
open(IN, "<", $in_file) || die "ERROR unable to open file $in_file for reading";

while(my $line = <IN>) { 
  chomp $line;
  if($line =~ m/^\>/) { 
    if($line =~ /^\>(orf\d+)\s+source\=(\S+)\s+coords\=(\d+)\.\.(\d+)\s+length\=(\d+)\s+frame\=(\d+)\s+desc\=(.*)$/) { 
      my ($orf, $source, $start, $stop, $length, $frame, $desc) = ($1, $2, $3, $4, $5, $6, $7);
      my $name = $source . "/" . $start . "-" . $stop;
      if($do_orf) { 
        $name .= "/" . $orf; 
      }
      if($do_length) { 
        $name .= "/l" . $length; 
      }
      if($do_frame) { 
        $name .= "/f" . $frame; 
      }
      print(">$name $desc\n");
    }
    else { 
      die "ERROR unable to parse header line $line";
    }
  }
  else { 
    print $line . "\n";
  }
}
close(IN);
