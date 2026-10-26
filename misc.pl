# Copyright 2012 - 2013, Steve Rader
# Copyright 2013 - 2018, Scott Kostyshak

sub audit {
  if ( $audit ) {
    print AUDIT "$$ ";
    print AUDIT @_;
    print AUDIT "\r\n";
  }
}

#------------------------------------------------------------------

sub clean_exit {
  unless( $audit ) {
    &shell_exec([$clear], 'no-wait');
  }
  if ( $audit ) {
      close(AUDIT) or die "$!";
  }

  endwin() unless isendwin();
  print "vit: audit log in $audit_file\n" if $audit;
  exit();
}

#------------------------------------------------------------------

sub error_exit {
  # do not exit VIT if we are in a try/catch block
  if ( $during_try ) {
    return
  }
  unless( $audit ) {
    &shell_exec([$clear], 'no-wait');
  }

  endwin();
  print STDERR "VIT fatal error: @_\r\n";

  if ( $audit ) {
      close(AUDIT) or die "$!";
  }

  exit(1);
}

#------------------------------------------------------------------

sub debug {
  print AUDIT @_;
  print AUDIT "\r\n";
}

#------------------------------------------------------------------

sub is_printable {
  my $char = $_[0];
  if ( $char =~ /^[0-9]+$/ && $char >= KEY_MIN ) {
    return 0;
  }
  if ( $char =~ /[[:cntrl:]]/ ) {
    return 0;
  }
  return 1;
}

#------------------------------------------------------------------

sub task_version {
  my $request = $_[0];
  my $version;
  *IN = &task_open({ bare => 1, err => 'merge' }, '--version');
  while(<IN>) {
    chop;
    $version = $_;
  }
  close(IN);
  if ( $request eq "major.minor" ) {
    my @v_ = split(/\./,$version);
    return "$v_[0].$v_[1]";
  }
  return $version;
}

#------------------------------------------------------------------
# on_path NAME -- true when an executable NAME is on PATH

sub on_path {
  my ($name) = @_;
  return scalar grep { -x "$_/$name" } split(/:/, $ENV{'PATH'} || '');
}

#------------------------------------------------------------------
# ui -- the program for what the user sees and does (the report, writes,
# terminal commands): tw when it's installed, so its shortcuts, contexts,
# themes and wrappers apply; task otherwise. vit's own bookkeeping reads
# (stats, projects, tags, _get) always use $task. Asked each time: cheap.

sub ui {
  return &on_path('tw') ? 'tw' : $task;
}

#------------------------------------------------------------------
# tw_wrappers -- tw's command wrapper keywords (ann, deps, ...), from tw's own
# list; none without tw

sub tw_wrappers {
  return () if ! &on_path('tw');
  my $file = ( $ENV{'TW_TASK_DIR'} || "$ENV{'HOME'}/.task" ) . '/config/.tw_wrappers';
  open(my $in, '<', $file) or return ();
  my @names;
  while ( my $line = <$in> ) {
    chomp $line;
    my ($name, $script, $desc, $type) = split(/\|/, $line);
    push @names, $name if defined $type && $type eq 'command' && $name ne '';
  }
  close($in);
  return @names;
}

#------------------------------------------------------------------

sub task_info {
  my $n = $_[0];
  my $uuid = $report2uuid[$task_selected_idx] // return '';
  *IN = &task_open({ read => 1, err => 'merge' }, $uuid, 'information');
  while(<IN>) {
    chop;
    $_ =~ s/\x1b.*?m//g; # decolorize
    if ( $_ =~ /^$n\s+(.*)/ ) {
      my $v = $1;
      $v =~ s/\s+$//;
      close(IN);
      return $v;
    }
  }
  close(IN);
  return '';
}

#------------------------------------------------------------------

sub ungetstr {
  my $str = $_[0];
  my $err;
  foreach my $ch (reverse split('', $str)) {
    $err = ungetch($ch);
    if ( $err != 0 ) {
      error_exit("Shortcut is too long.");
    }
  }
  return '';
}

return 1;
