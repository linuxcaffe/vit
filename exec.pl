# Copyright 2012 - 2013, Steve Rader
# Copyright 2013 - 2018, Scott Kostyshak
#
# Running task. Nothing here goes through a shell except shell_exec of a
# string (the user's own :! commands, and commands a hook spooled).
# Fleet contract: ~/dev/awesome-taskwarrior/CONVENTIONS.md

# Globals ($task, $task_timeout, $spool_dir, ...) are set in vit.pl.

#------------------------------------------------------------------
# split_args TEXT -- a typed command line into words, the way a terminal
# splits it (quotes, backslashes), but nothing is expanded or run. With an
# unbalanced quote ("don't forget") the words are split on spaces.

sub split_args {
  my ($str) = @_;
  return () if !defined $str || $str =~ /^\s*$/;
  my @w = shellwords($str);
  @w = split(' ', $str) unless @w;
  return @w;
}

#------------------------------------------------------------------
# quote_args WORDS -- the words as one line that split_args gives back

sub quote_args {
  return join(' ', map {
    my $w = $_;
    if ( $w !~ m{^[\w\-.:+/@%=,^]+$} ) {
      $w =~ s/'/'\\''/g;
      $w = "'$w'";
    }
    $w;
  } @_);
}

#------------------------------------------------------------------
# task_open OPTS, ARGS -- start task with ARGS (no shell); returns a handle
# to read its output from, closed with task_close (or alias a bareword:
# *IN = &task_open(...); while(<IN>) ...; close(IN) also sets $?). OPTS:
#   read => 1     a read: rc.hooks=off (no on-launch/on-exit hooks)
#   write => 1    a write: rc.recurrence.confirmation=no, the TW_* contract
#   err => 'merge' (stderr into the output) or 'null' (default)
#   bare => 1     no rc. overrides at all (task --version takes none)
# stdin is /dev/null, so task never waits for an answer.

sub task_open {
  my ($opt, @args) = @_;
  my @rc = ();
  unless ( $opt->{bare} ) {
    push @rc, 'rc.confirmation=no';
    push @rc, 'rc.hooks=off' if $opt->{read};
    push @rc, 'rc.recurrence.confirmation=no' if $opt->{write};
  }
  my @argv = ($task, @rc, @args);
  unshift @argv, 'timeout', $task_timeout if $timeout_bin;
  &audit("EXEC " . quote_args(@argv));
  my %env = ();
  if ( $opt->{write} ) {
    %env = ( TW_NOINTERACT => '1', TW_CLIENT => 'vit',
             TW_PREFLIGHT_CMD => quote_args(@args),
             TW_SPOOL_DIR => &spool_dir() );
  }
  my $pid = open(my $fh, '-|');
  if ( ! defined $pid ) {
    &error_exit("can not fork: $!");
  }
  if ( $pid == 0 ) {
    $SIG{__DIE__} = 'DEFAULT';
    $SIG{__WARN__} = 'DEFAULT';
    @ENV{keys %env} = values %env;
    open(STDIN, '<', '/dev/null');
    if ( ($opt->{err} || 'null') eq 'merge' ) {
      open(STDERR, '>&', \*STDOUT);
    } else {
      open(STDERR, '>', '/dev/null');
    }
    exec { $argv[0] } @argv;
    print "vit: can not run $argv[0]: $!\n";
    POSIX::_exit(127);
  }
  return $fh;
}

# task_close HANDLE -- the exit status ($?)
sub task_close {
  my ($fh) = @_;
  close($fh);
  return $?;
}

#------------------------------------------------------------------
# task_read ARGS -- a read; returns its lines (stderr merged, no newlines)

sub task_read {
  my $fh = &task_open({ read => 1, err => 'merge' }, @_);
  my @lines = <$fh>;
  &task_close($fh);
  chomp(@lines);
  return @lines;
}

#------------------------------------------------------------------
# task_check ARGS -- a read for its exit status only (0: something matched)

sub task_check {
  my $fh = &task_open({ read => 1 }, @_);
  1 while <$fh>;
  return &task_close($fh);
}

#------------------------------------------------------------------
# task_get NAME -- one DOM value ('rc.data.location', '3.uuid'), '' if none

sub task_get {
  my $fh = &task_open({ read => 1 }, '_get', @_);
  my $line = <$fh>;
  &task_close($fh);
  $line = '' if ! defined $line;
  chomp $line;
  return $line;
}

#------------------------------------------------------------------
# task_uuids IDS -- { id => uuid } for the IDs that exist now, in one call

sub task_uuids {
  my %seen;
  my @ids = grep { /^\d+$/ && $_ > 0 && !$seen{$_}++ } @_;
  return () if ! @ids;
  my $fh = &task_open({ read => 1 }, '_get', map { "$_.uuid" } @ids);
  my $line = <$fh>;
  &task_close($fh);
  return () if ! defined $line;
  chomp $line;
  my @uuids = split(/ /, $line, -1);
  my %map;
  for my $i (0 .. $#ids) {
    $map{$ids[$i]} = $uuids[$i] if defined $uuids[$i] && $uuids[$i] ne '';
  }
  return %map;
}

#------------------------------------------------------------------
# selected_uuid -- the selected line's task, or undef (and an error shown)

sub selected_uuid {
  my $uuid = $report2uuid[$task_selected_idx];
  if ( ! defined $uuid ) {
    $error_msg = "No task on this line.";
    &draw_error_msg();
    return undef;
  }
  return $uuid;
}

#------------------------------------------------------------------
# task_exec ARGS -- a write, output captured; returns ($status, $text).
# A hook that needs a terminal (tw_needs_pty, TW_INTERACTIVE_REQUIRED) gets
# the same command again in the terminal, if the user says so. Commands a
# hook spooled are offered afterwards.

sub task_exec {
  my @args = @_;
  my $es = 0;
  my $result = '';
  my $needs_pty = 0;
  my $fh = &task_open({ write => 1, err => 'merge' }, @args);
  while(<$fh>) {
    chomp;
    $_ =~ s/\x1b.*?m//g; # decolorize
    if ( $_ =~ /^\w+ override:?/ ) { next; }
    if ( $_ =~ /^\s*\{.*"type"\s*:\s*"tw_needs_pty"/ ) { $needs_pty = 1; next; }
    if ( $_ =~ /TW_INTERACTIVE_REQUIRED/ ) { $needs_pty = 1; next; }
    $result .= "$_ ";
  }
  $es = &task_close($fh);
  if ( $es != 0 ) {
    &audit("FAILED \"" . quote_args(@args) . "\" returned exit status $es");
  }
  if ( $es != 0 && $needs_pty ) {
    if ( &prompt_y("A hook needs a terminal for 'task " . quote_args(@args) . "'. Run it here? ") ) {
      $es = &shell_exec([$task, @args], 'forcewait');
      $result = ( $es == 0 ) ? "Ran in the terminal." : "Failed in the terminal.";
    } else {
      $result = "Not done: a hook needs a terminal for it.";
      $es ||= 1;
    }
  }
  &drain_spool();
  return ($es,$result);
}

#------------------------------------------------------------------

sub spool_dir {
  if ( ! defined $spool_dir ) {
    $spool_dir = File::Temp::tempdir('vit-spool.XXXXXX', TMPDIR => 1, CLEANUP => 1);
  }
  return $spool_dir;
}

# drain_spool -- offer each command a hook left in TW_SPOOL_DIR, once
sub drain_spool {
  return if ! defined $spool_dir;
  for my $f ( sort glob("$spool_dir/*.cmd") ) {
    open(my $in, '<', $f) or next;
    my $cmd = <$in>;
    close($in);
    unlink($f);
    next if ! defined $cmd;
    chomp $cmd;
    next if $cmd eq '';
    if ( &prompt_y("A hook asks to run: $cmd  Run it? ") ) {
      &shell_exec($cmd, 'forcewait');
    }
  }
}

#------------------------------------------------------------------

sub exited_successfully {
  my $status = shift || 0;
  return 1  if  WIFEXITED($status) and WEXITSTATUS($status)==0;
  return undef;
}

#------------------------------------------------------------------
# shell_exec CMD, MODE -- run CMD in the terminal (curses suspended).
# CMD is an array ref of argv (no shell), or a string for /bin/sh (the
# user's :! commands, spooled hook commands). Hooks get a real terminal:
# TW_NOINTERACT and the rest of the no-terminal contract are cleared.
# Returns the exit status.

sub shell_exec {
  my ($cmd,$mode) = @_;
  endwin();
  if ( $clear ne 'NOT_FOUND' ) { system { $clear } $clear; }
  my $shown = ref($cmd) ? quote_args(@$cmd) : $cmd;
  if ( $audit ) {
    print "$shown\r\n";
  }
  my $pid = fork();
  if ( defined $pid && $pid == 0 ) {
    $SIG{__DIE__} = 'DEFAULT';
    $SIG{__WARN__} = 'DEFAULT';
    delete @ENV{grep { /^(TW_NOINTERACT|TW_WEB|TW_SPOOL_DIR|TW_PREFLIGHT_)/ } keys %ENV};
    $ENV{TW_CLIENT} = 'vit';
    &audit("EXEC $shown");
    if ( ref($cmd) ) {
      exec { $cmd->[0] } @$cmd;
    } else {
      exec { '/bin/sh' } '/bin/sh', '-c', $cmd;
    }
    print "vit: can not run $shown: $!\n";
    POSIX::_exit(127);
  }
  waitpid($pid, 0) if defined $pid;
  my $status = $?;
  my $success = &exited_successfully($status);
  # two reasons to wait:
  # - an error occurred
  # - $mode is wait and the user didn't specify nowait in config file
  if ( not $success or ( $mode eq 'wait' and not $nowait ) or $mode eq 'forcewait' ) {
    if (not $success) {
      print "Error while executing command `$shown'\n";
    }
    print "Press return to continue.\r\n";
    <STDIN>;
  }
  &init_curses('refresh');
  &draw_screen();
  return $status;
}

return 1;
