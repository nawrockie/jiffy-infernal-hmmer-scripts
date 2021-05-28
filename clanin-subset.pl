#!/usr/bin/env perl
# 
# clanin-subset.pl: remove IDs and clans from a .clanin file 
#                   that are not present in a list of accessions.
#                        
# EPN, Fri May 28 13:37:29 2021
# 
#
use strict;
use warnings;
use Getopt::Long;

my $in_acclist = "";   # name of input list of accessions
my $in_cmstat  = "";

my $usage;
$usage  = "clanin-subset.pl\n\n";
$usage .= "Usage:\n\n";
$usage .= "clanin-subset.pl\n\t";
$usage .= "<file with list of subset of accessions to keep in clanin file\n\t";
$usage .= "<cmstat output from CM file that <input clanin file> pertains to>\n\t";
$usage .= "<input clanin file>\n\n";

if(scalar(@ARGV) != 3) { die $usage; }
my ($acclist, $cmstat, $clanin) = @ARGV;

my %keep_acc_H = ();
open(ACCLIST, $acclist) || die "ERROR unable to open $acclist for reading";
my $line;
while($line = <ACCLIST>) { 
  chomp $line;
  $line =~ s/^\s+//;
  $line =~ s/\s+$//;
  if($line ne "") { 
    $keep_acc_H{$line} = 1;
  }
}
close(ACCLIST);

my %acc2id_H = ();
my %id2acc_H = ();
my %acc_H = ();
my %id_H = ();
open(CMSTAT, $cmstat) || die "ERROR unable to open $cmstat for reading";
while($line = <CMSTAT>) { 
  chomp $line;
##                                                                                              rel entropy
##                                                                                             ------------
## idx   name                  accession      nseq  eff_nseq   clen      W   bps  bifs  model     cm    hmm
## ----  --------------------  ---------  --------  --------  -----  -----  ----  ----  -----  -----  -----
#     1  5S_rRNA               RF00001         712      7.35    119    194    34     1     cm  0.590  0.370
  if($line =~ /^\s*\d+\s+(\S+)\s+(\S+)/) { 
    my ($id, $acc) = ($1, $2); 
    if(defined $acc_H{$acc}) { 
      die "ERROR read accession $acc twice in cmstat file $cmstat"; 
    }
    if(defined $id_H{$id}) { 
      die "ERROR read accession $id twice in cmstat file $cmstat"; 
    }
    $acc2id_H{$acc} = $id;
    $id2acc_H{$id}  = $acc;
    $acc_H{$acc} = 1;
    $id_H{$id} = 1;
  }
}
close(CMSTAT);

open(CLANIN, $clanin) || die "ERROR unable to open $clanin for reading";
my %clan_H = ();
my %clan_HA = ();
my $clan;
my $id;
my $acc;
while($line = <CLANIN>) { 
#CL00110	mir-19	mir-363
  chomp $line;
  if($line =~ m/\w/) { 
    my @el_A = split(/\s+/, $line);
    if($el_A[0] !~ m/^CL/) { 
      die "ERROR first token on clanin line $line does not start with CL";
    }
    my $i;
    $clan = $el_A[0];
    if(defined $clan_H{$clan}) { 
      die "ERROR read clan $clan twice in clanin file";
    }
    $clan_H{$clan} = 1;
    @{$clan_HA{$clan}} = ();
    for($i = 1; $i < scalar(@el_A); $i++) { 
      if(! defined $id2acc_H{$el_A[$i]}) { 
        die "ERROR did not read id $el_A[$i] listed in $clanin file in cmstat file $cmstat";
      }
      $acc = $id2acc_H{$el_A[$i]};
      if(defined $keep_acc_H{$acc}) { 
        push(@{$clan_HA{$clan}}, $el_A[$i]);
      }
    }
    if(scalar(@{$clan_HA{$clan}}) > 1) { 
      # more than one family from this clan is listed in $acclist, output it
      print $clan;
      foreach $id (@{$clan_HA{$clan}}) { 
        print "\t" . $id;
      }
      print "\n";
    }
  }
}
close(CLANIN);
