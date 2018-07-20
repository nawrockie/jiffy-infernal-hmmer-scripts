# Total CPU time:2.51u 0.30s 00:00:02.80 Elapsed: 00:00:04.90
$tot_ct = 0;
$time_ct = 0;
$total_seconds;
while($line = <>) { 
  $tot_ct++;
  if($line =~ m/CPU time/) { 
    chomp $line;
    $time_ct++;
    if($line =~ /^.+Elapsed\:\s+(\S+)/) { 
      ($hours, $minutes, $seconds) = split(":", $1);
      $tot_secs += 3600 * $hours;
      $tot_secs += 60 * $minutes;
      $tot_secs += $seconds;
    }
    else { 
      die "ERROR couldn't find Elapsed time on CPU time line: $line";
    }
  }
}

printf("$tot_ct lines; $time_ct times; total time: %.2f minutes (avg: %.2f minutes)\n", ($tot_secs/60.), ($tot_secs/60.) / $time_ct);
    
