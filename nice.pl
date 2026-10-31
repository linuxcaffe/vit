#------------------------------------------------------------------
# Nice dates and times: date columns read Yesterday / Today / Tomorrow 3pm /
# Thursday / Nov20 / Apr1'27 instead of the dateformat. The settings are
# nicedates.rc's (included from the taskrc, so task _show has them): nicedates=on|off,
# nice.format.present|week|month|year|time, nice.conceal-times. The vitrc's
# "set nicedates=no|yes" overrides nicedates=; Ctrl-N flips it for the session.
#
# vit doesn't rewrite a laid-out report blindly (that is what broke the nicedates
# wrapper): the report runs with rc.dateformat.report set to 'Y-M-D H:N' padded to
# the widest label the formats can make (nice_dateformat), so task sizes every
# column for it. Then a column is a date column when each of its cells is blank or
# exactly that (nice_lines), and each such cell becomes its label, as wide as the
# cell. Other columns, styles (due.relative, ...) and annotations are left alone.

# nice_config KEY=VALUE... -- from task _show, at start (env.pl)
sub nice_config {
  for (@_) {
    $nice_cfg{$1} = $2 if /^(nicedates|nice\.[\w.-]+)=(.*)$/;
  }
  $nice = ( $nice_cfg{'nicedates'} // '' ) eq 'on';
  $nice = ( $nicedates_vitrc eq 'yes' ) if defined $nicedates_vitrc;
  $nice_width = undef;
}

sub nice_setting {
  my ($k) = @_;
  my %default = ( 'nice.format.present' => 'Yesterday,Today,Tomorrow',
                  'nice.format.week' => 'A', 'nice.format.month' => 'bd',
                  'nice.format.year' => "''y", 'nice.format.time' => '',
                  'nice.conceal-times' => '00:00:00,23:59:59' );
  return $nice_cfg{$k} // $default{$k};
}

# nice_fmt FORMAT, Y, M, D, H, N -- a taskwarrior dateformat, as task would
# write it; '' (two apostrophes) is nicedates' literal apostrophe ('27)
sub nice_fmt {
  my ($fmt, $y, $mo, $d, $h, $mi) = @_;
  my $wd = ( localtime(timelocal(0, 0, 12, $d, $mo - 1, $y)) )[6];
  my %f = ( Y => $y, y => sprintf('%02d', $y % 100), M => sprintf('%02d', $mo), m => $mo + 0,
            D => sprintf('%02d', $d), d => $d + 0, b => substr($nice_months[$mo-1], 0, 3),
            B => $nice_months[$mo-1], A => $nice_days[$wd], a => substr($nice_days[$wd], 0, 3),
            H => sprintf('%02d', $h), h => $h + 0, N => sprintf('%02d', $mi), n => $mi + 0,
            S => '00', s => 0 );
  my $out = '';
  my @c = split(//, $fmt);
  for ( my $i = 0; $i <= $#c; $i++ ) {
    if ( $c[$i] eq "'" && $i < $#c ) {
      $i++;
      $out .= $c[$i];     # 'X: X itself; '': an apostrophe, and the next letter formats
      next;
    }
    $out .= exists $f{$c[$i]} ? $f{$c[$i]} : $c[$i];
  }
  return $out;
}

# nice_time H, N -- '' when it's a concealed time; 3pm, 3:30pm, else nice.format.time
sub nice_time {
  my ($h, $mi) = @_;
  for ( split(/,/, &nice_setting('nice.conceal-times')) ) {
    my ($ch, $cm) = /^\s*(\d+):(\d+)/ or next;
    return '' if $ch == $h && $cm == $mi;
  }
  my $fmt = &nice_setting('nice.format.time');
  return &nice_fmt($fmt, 2024, 1, 1, $h, $mi) if $fmt ne '';
  my $h12 = $h % 12 || 12;
  return $h12 . ( $mi != 0 ? sprintf(':%02d', $mi) : '' ) . ( $h < 12 ? 'am' : 'pm' );
}

# nice_date Y, M, D -- Yesterday/Today/Tomorrow, the week format for 2 to 7 days
# ahead, else the month format (plus the year format in another year)
sub nice_date {
  my ($y, $mo, $d) = @_;
  my @now = localtime();
  my $today = timelocal(0, 0, 12, $now[3], $now[4], $now[5] + 1900);
  my $days = POSIX::floor( ( timelocal(0, 0, 12, $d, $mo - 1, $y) - $today ) / 86400 + 0.5 );
  my @present = split(/,/, &nice_setting('nice.format.present'), -1);
  return $present[$days + 1] // '' if $days >= -1 && $days <= 1;
  return &nice_fmt(&nice_setting('nice.format.week'), $y, $mo, $d, 0, 0) if $days >= 2 && $days <= 7;
  my $s = &nice_fmt(&nice_setting('nice.format.month'), $y, $mo, $d, 0, 0);
  $s .= &nice_fmt(&nice_setting('nice.format.year'), $y, $mo, $d, 0, 0) if $y != $now[5] + 1900;
  return $s;
}

sub nice_label {
  my ($y, $mo, $d, $h, $mi) = @_;
  my $t = &nice_time($h, $mi);
  my $s = &nice_date($y, $mo, $d);
  return $t eq '' ? $s : "$s $t";
}

# nice_dateformat -- rc.dateformat.report for the report: 'Y-M-D H:N' and spaces,
# as wide as the widest label (every day of a leap year, every minute of a day)
sub nice_dateformat {
  if ( ! defined $nice_width ) {
    my $date = 0;
    $date = &max_width($date, split(/,/, &nice_setting('nice.format.present')));
    my $t = timelocal(0, 0, 12, 1, 0, 2024);
    for my $n ( 0 .. 365 ) {
      my ($d, $mo, $y) = ( localtime($t + $n * 86400) )[3, 4, 5];
      ($mo, $y) = ($mo + 1, $y + 1900);
      $date = &max_width($date, &nice_fmt(&nice_setting('nice.format.week'), $y, $mo, $d, 0, 0),
                         &nice_fmt(&nice_setting('nice.format.month'), $y, $mo, $d, 0, 0)
                         . &nice_fmt(&nice_setting('nice.format.year'), $y, $mo, $d, 0, 0));
    }
    my $time = 0;
    for my $m ( 0 .. 24 * 60 - 1 ) {
      $time = &max_width($time, &nice_time(int($m / 60), $m % 60));
    }
    $nice_width = $date + ( $time ? 1 + $time : 0 );
    $nice_width = 16 if $nice_width < 16;
  }
  return 'Y-M-D H:N' . ( ' ' x ( $nice_width - 16 ) );
}

sub max_width {
  my ($w, @s) = @_;
  for (@s) { my $n = mbswidth($_); $w = $n if $n > $w; }
  return $w;
}

# nice_chars LINE -- its visible characters: [screen column, offset in LINE]
sub nice_chars {
  my ($line) = @_;
  my @chars;
  my $col = 0;
  while ( $line =~ /\G(?:\x1b\[[0-9;]*m)*(.)/gs ) {
    push @chars, [ $col, $-[1] ];
    my $w = mbswidth($1);
    $col += $w > 0 ? $w : 0;
  }
  return @chars;
}

# nice_spans HEADER, RULE -- the columns, [start, width]: the runs of dashes in the
# rule under the header (no underline), else the header's labels (each its own
# coloured run, as wide as its column)
sub nice_spans {
  my ($header, $rule) = @_;
  my @spans;
  if ( defined $rule ) {
    ( my $r = $rule ) =~ s/\x1b\[[0-9;]*m//g;
    while ( $r =~ /(-+)/g ) { push @spans, [ $-[1], length $1 ]; }
    return @spans;
  }
  my $col = 0;
  my $styled = 0;
  for my $part ( split(/(\x1b\[[0-9;]*m)/, $header) ) {
    if ( $part =~ /^\x1b\[([0-9;]*)m$/ ) {
      $styled = ( $1 ne '0' && $1 ne '' );
      next;
    }
    my $w = mbswidth($part);
    $w = length($part) if $w < 0;
    push @spans, [ $col, $w ] if $styled && $w > 0;
    $col += $w;
  }
  return @spans;
}

# nice_lines LINES -- the report's lines, date cells as labels
sub nice_lines {
  my @lines = @_;
  my $plain = sub { ( my $s = $_[0] ) =~ s/\x1b\[[0-9;]*m//g; return $s; };
  my ($h) = grep { $plain->($lines[$_]) =~ /\S/ } 0 .. $#lines;
  return @lines if ! defined $h;
  my $first = $h + 1;
  my $rule;
  if ( $first <= $#lines && $plain->($lines[$first]) =~ /^[\s-]*-[\s-]*$/ ) {
    $rule = $lines[$first++];
  }
  my $last = $first - 1;
  $last++ while $last < $#lines && $plain->($lines[$last + 1]) =~ /\S/;
  my @spans = &nice_spans($lines[$h], $rule);
  my @rows = map { [ &nice_chars($lines[$_]) ] } $first .. $last;
  my @dates = grep {
    my $span = $_;
    my $seen = 0;
    my $ok = 1;
    for my $r ( $first .. $last ) {
      my $text = &nice_cell_text($lines[$r], $rows[$r - $first], $span);
      next if $text =~ /^\s*$/;
      if ( $text =~ /^\d{4}-\d\d-\d\d \d\d:\d\d\s*$/ ) { $seen = 1; } else { $ok = 0; last; }
    }
    $ok && $seen;
  } @spans;
  for my $r ( $first .. $last ) {
    for my $span ( reverse @dates ) {
      my @in = grep { $_->[0] >= $span->[0] && $_->[0] < $span->[0] + $span->[1] }
               @{ $rows[$r - $first] };
      next if ! @in || grep { $in[$_][1] != $in[0][1] + $_ } 0 .. $#in;
      my $text = substr($lines[$r], $in[0][1], scalar(@in));
      my ($y, $mo, $d, $hh, $mi) = $text =~ /^(\d{4})-(\d\d)-(\d\d) (\d\d):(\d\d)/ or next;
      my $label = &nice_label($y, $mo, $d, $hh, $mi);
      my $pad = scalar(@in) - mbswidth($label);
      $label = substr($label, 0, scalar(@in)) if $pad < 0;
      substr($lines[$r], $in[0][1], scalar(@in)) = $label . ( ' ' x ( $pad > 0 ? $pad : 0 ) );
    }
  }
  return @lines;
}

# nice_cell_text LINE, CHARS, SPAN -- the visible text of LINE in SPAN
sub nice_cell_text {
  my ($line, $chars, $span) = @_;
  return join('', map { substr($line, $_->[1], 1) }
                  grep { $_->[0] >= $span->[0] && $_->[0] < $span->[0] + $span->[1] } @$chars);
}

return 1;
