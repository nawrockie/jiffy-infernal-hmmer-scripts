#!/usr/bin/env perl
# EPN, Tue Jul  3 06:59:56 2018
# ali-pfam-sindi2dot-bracket.pl
#
# Given a pfam formatted alignment with per-sequence secondary structure annotation (#=GR <seqname> SS) 
# convert it to unaligned fasta dot-bracket notation.
#
use warnings;
use strict;
use Getopt::Long;

my $usage;
$usage  = "ali-pfam-sindi2dot-bracket.pl\n\n";
$usage .= "Usage:\n\n";
$usage .= "ali-pfam-sindi2dot-bracket.pl\n";
$usage .= "\tOPTIONS:\n";
$usage .= "\t\t-a: keep sequences in aligned format (do not remove gaps) [default: do remove gaps]\n";
$usage .= "\t\t-l: do not convert sequences to all uppercase [default: do]\n";
$usage .= "\t\t-w: leave SS in current format (possibly WUSS)\n";
$usage .= "\t\t-c: include consensus structure as additional 'sequence' [default: do not]\n";
$usage .= "\t\t-n: name individual secondary structures [default: do not]\n";

my $opt_a = 0; # set to '1' if -a used
my $opt_l = 0; # set to '1' if -l used
my $opt_w = 0; # set to '1' if -w used
my $opt_c = 0; # set to '1' if -c used
my $opt_n = 0; # set to '1' if -n used

&GetOptions( "a"  => \$opt_a,
             "l"  => \$opt_l,
             "w"  => \$opt_w,
             "c"  => \$opt_c,
             "n"  => \$opt_n);

if(scalar(@ARGV) != 1) { die $usage; }

my ($aln_file) = (@ARGV);

# set defaults
my $do_gapless    = ($opt_a) ? 0 : 1;
my $do_upper      = ($opt_l) ? 0 : 1;
my $do_dotbracket = ($opt_w) ? 0 : 1;
my $do_sscons     = ($opt_c) ? 1 : 0;
my $do_name       = ($opt_n) ? 1 : 0;

my %seen_H      = ();    # key is sequence name, used to check to make sure we are in Pfam format
my %seen_ss_H   = ();    # key is sequence name, used to check to make sure we are in Pfam format
my @notgap_A    = ();    # array 1..$i..alen-1, value is '0' if position $i is a gap for current sequence, '1' if it is not a gap
my $seqname     = undef; # current sequence name
my $seqname_ss  = undef; # current sequence name for SS line
my $seq         = undef; # current sequence, with gaps
my $gapless_seq = undef; # current sequence, without gaps
my $ss          = undef; # current SS string, with gaps
my $gapless_ss  = undef; # current SS string, without gaps
my @seq_A       = ();    # array version of current sequence, one element per position
my @ss_A        = ();    # array version of current SS line, one element per position
my $i           = 0;     # counter over alignment positions
my $left_ct     = 0;     # number of left basepair halves seen for current SS string
my $right_ct    = 0;     # number of right basepair halves seen for current SS string
my $line        = undef; # a line of the file
my $ss_name     = undef; # name for current SS string, will always be "" unless -n used
my $is_sscons   = 0;     # flag for whether current SS string is indi SS or SS_cons

open(IN, $aln_file) || die "ERROR unable to open $aln_file"; 

while(my $line = <>) { 
  if($line !~ /^\#/) { 
    if($line =~ /(\S+)\s+(\S+)/) { 
      ($seqname, $seq) = ($1, $2);
      if((exists $seen_H{$seqname}) && ($seen_H{$seqname} == 1)) { 
        die "ERROR saw sequence $seqname twice, did you convert to pfam format (e.g. esl-reformat pfam ...)";
      }
      $seen_H{$seqname} = 1;

      # determine where the gaps in the sequence are
      $gapless_seq = "";
      @seq_A = split("", $seq);
      @notgap_A = ();
      for($i = 0; $i < scalar(@seq_A); $i++) { 
        if($seq_A[$i] eq "-") { 
          $notgap_A[$i] = 0; 
          if(! $do_gapless) { $gapless_seq .= $seq_A[$i]; }
        }
        else { 
          $gapless_seq .= $seq_A[$i];
          $notgap_A[$i] = 1; 
        }
      }
      # convert lowercase to uppercase
      if($do_upper) { $gapless_seq =~ tr/a-z/A-Z/; }
    }
  }      
  elsif($line =~ m/^\#=/) { # check all #= lines to see if they're either indi SS or SS_cons
    ($ss, $seqname_ss) = (undef, undef); 
    if($line =~ /^\#=GR\s+(\S+)\s+SS\s+(\S+)/) { # indi SS line
      ($seqname_ss, $ss) = ($1, $2);
      $seen_ss_H{$seqname_ss} = 1;
      if($seqname_ss ne $seqname) { 
        die "ERROR did not read SS line for $seqname in expected order, read SS for $seqname_ss instead"; 
      }
      $is_sscons = 0;
    }
    elsif($line =~ /^\#=GC\s+SS_cons\s+(\S+)/) { # SS_cons line
      $ss = ($1);
      $seqname_ss = "SS_cons";
      $is_sscons = 1;
    }
    if(defined $ss) { # only true if either an indi SS line or SS_cons line
      # remove gaps, creating SS as we go, we need @gap_A to do this because SS string does not indicate where gaps are
      $left_ct  = 0;
      $right_ct = 0;
      $gapless_ss = "";
      @ss_A = split("", $ss);
      for($i = 0; $i < scalar(@ss_A); $i++) { 
        if(($notgap_A[$i] == 1) || (! $do_gapless)) { 
          if($ss_A[$i] =~ m/[\{\[\<\(]/) {
            $left_ct++;
            $gapless_ss .= ($do_dotbracket) ? "(" : $ss_A[$i];
          }
          elsif($ss_A[$i] =~ m/[\}\]\>\)]/) {
            $right_ct++;
            $gapless_ss .= ($do_dotbracket) ? ")" : $ss_A[$i];
          }
          else { 
            $gapless_ss .= ($do_dotbracket) ? "." : $ss_A[$i];
          }
        }
      }
      # output
      if(! $is_sscons) { 
        # sanity checks:
        if(length($gapless_seq) != length($gapless_ss)) { 
          die "ERROR problem removing gaps from SS for $seqname, unexpected length " . length($gapless_seq) . " != " . length($gapless_ss) . "\n";
        }
        if($left_ct != $right_ct) { 
          die "ERROR problem with SS for $seqname, num left parentheses ($left_ct) not equal to num right parentheses ($right_ct)\n";
        }
        $ss_name = ($do_name) ? ">$seqname-SS\n" : "";
        print(">$seqname\n$gapless_seq\n$ss_name$gapless_ss\n");
      }
      elsif($is_sscons && $do_sscons) { 
        # sanity checks:
        if(length($gapless_seq) != length($gapless_ss)) { 
          die "ERROR problem removing gaps from SS_cons, unexpected length " . length($gapless_seq) . " != " . length($gapless_ss) . "\n";
        }
        if($left_ct != $right_ct) { 
          die "ERROR problem with SS_cons, num left parentheses ($left_ct) not equal to num right parentheses ($right_ct), maybe you want to also use -a?\n";
        }
        $ss_name = ($do_name) ? ">SS_cons\n" : "";
        print("$ss_name$gapless_ss\n");
      }
    } # end of 'if(defined $ss)'
  } # end of 'elsif($line =~ m/^\#=/) {'
}
close(IN);

# sanity check
foreach $seqname (sort keys %seen_H) { 
  if((! exists $seen_ss_H{$seqname}) || ($seen_ss_H{$seqname} != 1)) { 
    die "ERROR did not read SS annotation for $seqname\n"; 
  }
}
foreach $seqname (sort keys %seen_ss_H) { 
  if((! exists $seen_H{$seqname}) || ($seen_H{$seqname} != 1)) { 
    die "ERROR did not read sequence, but did read SS annotation for $seqname\n"; 
  }
}
