use strict;
use warnings;
use Getopt::Long;

my $usage;
$usage  = "hmmsearch2sfetch.pl\n\n";
$usage .= "Usage:\n\n";
$usage .= "hmmsearch2sfetch.pl [OPTIONS] <hmmsearch file>\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t-s     : fetch full sequences [default: domains]\n";
$usage .= "\t\t-t <x> : set minimum bit score for domain to fetch (or sequence if -s)\n";
$usage .= "\t\t-e <x> : set maximum E-value for domain to fetch (or sequence if -s)\n";
$usage .= "\t\t-i <x> : with -e, use independent E-value instead of conditional E-value\n";
$usage .= "\t\t-v     : fetch domains using envelope boundaries [default: use alignment boundaries]\n";
$usage .= "\t\t-q     : add query name to fetch sequence name\n\n";

my $do_sequence  = 0;
my $do_minbit    = 0;
my $minbit       = undef;
my $do_maxE      = 0;
my $maxE         = undef;
my $do_iE        = 0;
my $do_env       = 0;
my $do_queryname = 0;

&GetOptions( "s"         => \$do_sequence,
             "t=s"       => \$minbit,
             "e=s"       => \$maxE,
             "i"         => \$do_iE,
             "q"         => \$do_queryname,
             "v"         => \$do_env);

if(scalar(@ARGV) != 1) { die $usage; }
my ($in_hmmsearch) = @ARGV;

if(defined $minbit) { 
  $do_minbit = 1;
}
if(defined $maxE) { 
  $do_maxE = 1;
}
# enforce incompatible/required option combinations
if($do_minbit && $do_maxE) { 
  die "ERROR, -t and -e are incompatible, pick one"; 
}
if($do_env && $do_sequence) { 
  die "ERROR, -v and -s are incompatible, pick one";
}
if($do_queryname && $do_sequence) { 
  die "ERROR, -q and -s are incompatible, pick one";
}
if(($do_iE) && (! $do_maxE)) { 
  die "ERROR, -i only works in combination with -e";
}

#Query:       TROVE  [M=392]
#Accession:   PF05731.10
#Description: TROVE domain
#Scores for complete sequences (score includes all domains):
#   --- full sequence ---   --- best 1 domain ---    -#dom-
#    E-value  score  bias    E-value  score  bias    exp  N  Sequence   Description
#    ------- ------ -----    ------- ------ -----   ---- --  --------   -----------
#    1.6e-84  287.7   0.0    1.2e-41  146.5   0.0    2.1  2  AAN16852.1  gp220 [Mycobacterium phage Bxz1]
#    9.8e-83  281.8   0.0    1.6e-41  146.1   0.0    2.1  2  AON96972.1  RNA binding protein [Mycobacterium phage Tonenili
#    1.1e-82  281.6   0.0      4e-44  154.7   0.0    2.1  2  AII28180.1  Ro protein [Mycobacterium phage Sparky]
#    1.5e-78  268.0   0.0    1.1e-76  261.9   0.0    2.0  1  ACH62194.1  gp227 [Mycobacterium phage Myrna]
#    6.1e-61  210.0   0.0    8.2e-31  110.8   0.0    2.1  2  AIW02618.1  Ro protein [Streptomyces phage Jay2Jay]
#    8.2e-14   54.9   0.0    1.1e-06   31.4   0.0    2.4  2  AGM11427.1  hypothetical protein HGTV1_129 [Halovirus HGTV-1]
#    2.9e-11   46.5   0.0    0.00012   24.7   0.0    2.1  2  AFU88009.1  putative TROVE-like domain protein [Caulobacter p
#    0.00038   23.0   0.0    0.00066   22.3   0.0    1.4  1  AEO93797.1  gp540 [Bacillus virus G]
#
#
#Domain annotation for each sequence:
#>> AAN16852.1  gp220 [Mycobacterium phage Bxz1]
#   #    score  bias  c-Evalue  i-Evalue hmmfrom  hmm to    alifrom  ali to    envfrom  env to     acc
# ---   ------ ----- --------- --------- ------- -------    ------- -------    ------- -------    ----
#   1 !  146.5   0.0   4.7e-46   1.2e-41       1     177 [.      24     188 ..      24     202 .. 0.94
#   2 !  139.1   0.0   8.4e-44   2.1e-39     251     392 .]     226     367 ..     216     367 .. 0.97

my $line;
my $query;
my $querylen;
while($line = <>) { 
  if($line =~ /^Query\:\s+(\S+)\s+\[M=\d+\]/) { 
    # in query score section
    ($query, $querylen) = ($1, $2);
    $line = <>;
    while($line !~ m/^[\s+\-]+\n$/) { # match line with only spaces and '-'
      $line = <>;
    }
    $line = <>;
    while($line =~ /\S/) { # while we don't have a blank line
      $line =~ s/^\s+//; # remove leading whitespace
      #    E-value  score  bias    E-value  score  bias    exp  N  Sequence   Description
      #    ------- ------ -----    ------- ------ -----   ---- --  --------   -----------
      #    1.6e-84  287.7   0.0    1.2e-41  146.5   0.0    2.1  2  AAN16852.1  gp220 [Mycobacterium phage Bxz1]
      chomp $line;
      if($line =~ /(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)$/) { 
        my ($seq_evalue, $seq_score, $seq_bias, $best_evalue, $best_score, $best_bias, $exp, $N, $sequence, $description) = 
            ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
        if($do_sequence) { 
          if   ($do_minbit && ($seq_score  < $minbit)) { ; } # skip
          elsif($do_maxE   && ($seq_evalue > $maxE))   { ; } # skip
          else { 
            print $sequence . "\n";
          }
        }
      }
      elsif($line =~ m/^\s*\-+\s+inclusion threshold\s+\-+\s*\n*$/) {
          # special line: '------ inclusion threshold ------'
          ; # skip
      }
      else { 
        die "ERROR unable to parse line in query score section: $line\n"; 
      }
      $line = <>;
    }
  }
  elsif($line =~ /^\>\>/) { 
    #>> AAN16852.1  gp220 [Mycobacterium phage Bxz1]
    ##    score  bias  c-Evalue  i-Evalue hmmfrom  hmm to    alifrom  ali to    envfrom  env to     acc
    #---   ------ ----- --------- --------- ------- -------    ------- -------    ------- -------    ----
    #1 !  146.5   0.0   4.7e-46   1.2e-41       1     177 [.      24     188 ..      24     202 .. 0.94
    #2 !  139.1   0.0   8.4e-44   2.1e-39     251     392 .]     226     367 ..     216     367 .. 0.97
    
    chomp $line;
    if($line =~ m/^\>\>\s*(\S+)\s+(.*)$/) { 
      my ($sequence, $description) = ($1, $2);
      $line = <>;
      chomp $line;
      if($line !~ m/^\s+\#\s+score\s+bias\s+c\-Evalue\s+i\-Evalue\s+hmmfrom\s+hmm to\s+alifrom\s+ali to\s+envfrom\s+env to\s+acc\s*/) { 
        die "ERROR unexpected 1st line in domain annotation for sequence $sequence:\n$line\n"; 
      }
      
      $line = <>;
      if($line !~ m/^[\s+\-]+\n$/) { 
        die "ERROR unexpected 2nd line in domain annotation for sequence $sequence:\n$line\n"; 
      }
      
      $line = <>;
      while($line =~ /\S/) { # while we don't have a blank line
        $line =~ s/^\s+//; # remove leading whitespace  }
        #  1 !  146.5   0.0   4.7e-46   1.2e-41       1     177 [.      24     188 ..      24     202 .. 0.94
        chomp $line;
        if($line =~ /(\d+)\s+(\S)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\S+)\s(\S+)$/) { 
          my ($domain_idx, $sigchar, $score, $bias, $cE, $iE, $hmmfrom, $hmmto, $hmmbounds, $alifrom, $alito, $alibounds, $envfrom, $envto, $envbounds, $acc) = 
              ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16);
          if(! $do_sequence) { 
            if   ($do_minbit  && ($score  < $minbit))          { ; } # skip
            elsif($do_maxE   && (! $do_iE) && ($cE > $maxE))   { ; } # skip
            elsif($do_maxE   && (  $do_iE) && ($iE > $maxE))   { ; } # skip
            else { 
              my $from = ($do_env) ? $envfrom : $alifrom;
              my $to   = ($do_env) ? $envto   : $alito;
              printf("%s/%s%d-%d %d %d %s\n", $sequence, ($do_queryname) ? $query . "/" : "", $from, $to, $from, $to, $sequence);
            }
          }
        }
        else { 
          die "ERROR unable to parse line in domain score section for sequence $sequence:\n$line\n"; 
        }
        $line = <>;
      }
    } # end of if($line =~ m/^\>\>...
    else { 
      die "ERROR unable to parse >> line:\n$line\n"; 
    }
  }
}
