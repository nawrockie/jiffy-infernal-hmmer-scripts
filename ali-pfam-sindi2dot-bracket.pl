#!/usr/bin/env perl
# EPN, Tue Jul  3 06:59:56 2018
# ali-pfam-sindi2dot-bracket.pl
#
# Given a pfam formatted alignment with per-sequence secondary structure annotation (#=GR <seqname> SS) 
# convert it to unaligned fasta dot-bracket notation.
#
use warnings;
use strict;

my $usage;
$usage  = "perl ali-pfam-sindi2dot-bracket.pl <alignment file in Pfam format with per-sequence SS annotation>\n\n";

if(scalar(@ARGV) != 1) { die $usage; }

my ($aln_file) = (@ARGV);

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
        }
        else { 
          $gapless_seq .= $seq_A[$i];
          $notgap_A[$i] = 1; 
        }
      }
      # convert lowercase to uppercase
      $gapless_seq =~ tr/a-z/A-Z/;
    }
  }      
  elsif($line =~ m/^\#=GR\s+(\S+)\s+SS\s+(\S+)/) { 
    ($seqname_ss, $ss) = ($1, $2);
    $seen_ss_H{$seqname_ss} = 1;
    if($seqname_ss ne $seqname) { 
      die "ERROR did not read SS line for $seqname in expected order, read SS for $seqname_ss instead"; 
    }
    # remove gaps, creating SS as we go, we need @gap_A to do this because SS string does not indicate where gaps are
    $left_ct  = 0;
    $right_ct = 0;
    $gapless_ss = "";
    @ss_A = split("", $ss);
    for($i = 0; $i < scalar(@ss_A); $i++) { 
      if($notgap_A[$i] == 1) { 
        if($ss_A[$i] =~ m/[\{\[\<\(]/) {
          $left_ct++;
          $gapless_ss .= "(";
        }
        elsif($ss_A[$i] =~ m/[\}\]\>\)]/) {
          $right_ct++;
          $gapless_ss .= ")";
        }
        else { 
          $gapless_ss .= ".";
        }
      }
    }
    if(length($gapless_seq) != length($gapless_ss)) { 
      die "ERROR problem removing gaps from SS for $seqname, unexpected length " . length($gapless_seq) . " != " . length($gapless_ss) . "\n";
    }
    if($left_ct != $right_ct) { 
      die "ERROR problem with SS for $seqname, num left parentheses ($left_ct) not equal to num right parentheses ($right_ct)";
    }

    # output
    print(">$seqname\n$gapless_seq\n$gapless_ss\n");
  }
}
close(IN);

# sanity check
foreach $seqname (sort keys %seen_H) { 
  if((! exists $seen_ss_H{$seqname}) || ($seen_ss_H{$seqname} != 1)) { 
    die "ERROR did not read SS annotation for $seqname"; 
  }
}
foreach $seqname (sort keys %seen_ss_H) { 
  if((! exists $seen_H{$seqname}) || ($seen_H{$seqname} != 1)) { 
    die "ERROR did not read sequence, but did read SS annotation for $seqname"; 
  }
}
