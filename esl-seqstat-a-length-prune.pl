# EPN, Fri Jul 20 10:03:34 2018
# esl-seqstat-a-prune-by-length.pl
# Prunes sequences in esl-seqstat -a output based on length.
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "perl esl-seqstat-a-prune-by-length.pl [OPTIONS] <esl-seqstat -a output>\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t--min <d>: min length to keep [default: 0]\n";
$usage .= "\t\t--max <d>: max length to keep [default: infinity]\n";

my $min = undef;
my $max = undef;
&GetOptions( "min=s" => \$min,
             "max=s" => \$max);

if(scalar(@ARGV) != 1) { die $usage; }

if((! defined $min) && (! defined $max)) { 
  die "ERROR either --min or --max must be set\n$usage";
}
if(! defined $min) { $min = 0; }
if(! defined $max) { $max = -1; }

#= AACY020001110.1/1555-1        1555 Marine metagenome 1096624980586, whole genome shotgun sequence

while(my $line = <>) { 
  if($line =~ /^=\s+\S+\s+(\d+)/) { 
    my $len = $1;
    if($len >= $min) { 
      if(($max == -1) || ($len <= $max)) { 
        print $line;
      }
    }
  }
}

exit 0;
