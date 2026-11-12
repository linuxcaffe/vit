# Copyright 2012 - 2013, Steve Rader
# Copyright 2013 - 2018, Scott Kostyshak

sub parse_report_line {
  my ($l,$str) = @_;
  &parse_line($l,$str);
  if ( $current_command eq 'summary' && $parsed_tokens[0] =~ /^(\d+) project/ ) {
    $num_projects = $1;
    return;
  }
  push @{ $report_tokens[$l] }, (@parsed_tokens);
  push @{ $report_colors_fg[$l] },  (@parsed_colors_fg);
  push @{ $report_colors_bg[$l] }, (@parsed_colors_bg);
  push @{ $report_attrs[$l] }, (@parsed_attrs);
}

#------------------------------------------------------------------

sub parse_line {
  my ($l,$str) = @_;
  my $fg = 999999;
  my $bg = 999999;
  my $attr = '';
  @parsed_tokens = ();
  @parsed_colors_fg = ();
  @parsed_colors_bg = ();
  @parsed_attrs = ();
  my @toks = split(/\x1B/,$str);
  my $t = 0;
  #debug("PARSE IN $str");
  for my $tok (@toks) {
    if ( $tok eq '' ) { next; }
    $attr = '';
    # one SGR sequence, \e[P;P;...m: attributes (0 1 4 7), 16 colours (30-37 40-47,
    # bright 90-97 100-107), 256 colours (38;5;N 48;5;N); anything else is ignored,
    # never turned into a colour (\e[4;7m once gave fg 7-30 = -23 and killed vit)
    if ( $tok =~ s/^\[([\d;]*)m// ) {
      my @p = map { $_ eq '' ? 0 : $_ } split(/;/, $1, -1);
      @p = (0) unless @p;
      while ( @p ) {
        my $a = shift @p;
        if ( ($a == 38 || $a == 48) && @p >= 2 && $p[0] == 5 ) {
          shift @p; my $n = shift @p;
          if ( $a == 38 ) { $fg = $n; } else { $bg = $n; }
        } elsif ( $a == 0 )  { $fg = $bg = 999999; $attr .= 'none '; }
        elsif ( $a == 1 )    { $attr .= 'bold '; }
        elsif ( $a == 4 )    { $attr .= 'underline '; }
        elsif ( $a == 7 )    { $attr .= 'inverse '; }
        elsif ( $a >= 30 && $a <= 37 )   { $fg = $a - 30; }
        elsif ( $a >= 40 && $a <= 47 )   { $bg = $a - 40; }
        elsif ( $a >= 90 && $a <= 97 )   { $fg = $a - 90 + 8; }
        elsif ( $a >= 100 && $a <= 107 ) { $attr .= 'standout '; $bg = $a - 100; } # "bright" in taskwarrior
      }
    }
    # FIXME summary mode...
    # if ( $tok =~ /0%\s+100%/ ) { debug("summary graph tok=\"$tok\" column=$t"); }
    if ( $tok ne '' ) {
      $parsed_tokens[$t] = $tok;
      $parsed_colors_fg[$t] = $fg;
      $parsed_colors_bg[$t] = $bg;
      if ( $attr eq '' ) { $attr = 'none'; }
      $parsed_attrs[$t] = $attr;
      #if ( $t == 0 ) { debug("PARSE OUT tok=\"$tok\" pos=$l.$t cp=$fg,$bg attr=$attr"); }
      $t++;
    }
  }
}

#------------------------------------------------------------------

sub extract_color {
  my ($s,$t) = @_;
  $parsed_colors_fg[1] = -1;
  $parsed_colors_bg[1] = -1;
  $parsed_attrs[1] = '';
  *IN2 = &task_open({ read => 1, err => 'merge' }, 'rc._forcecolor=on', 'color', &split_args($s));
  while(<IN2>){
    if ( $_ =~ /Your sample:/ ) {
      $_ = <IN2>; $_ = <IN2>;
      &parse_line(0,$_);
      if ( $parsed_colors_fg[1] eq '999999' ) { $parsed_colors_fg[1] = -1; }
      if ( $parsed_colors_bg[1] eq '999999' ) { $parsed_colors_bg[1] = -1; }
    }
  }
  close(IN2);
}

#------------------------------------------------------------------

return 1;

