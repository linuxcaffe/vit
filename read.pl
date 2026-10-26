# Copyright 2012 - 2013, Steve Rader
# Copyright 2013 - 2018, Scott Kostyshak

sub read_report {
  my ($mode) = @_;
  my $prev_uuid = $report2uuid[$task_selected_idx];
  my $prev_offset = $task_selected_idx - &first_line_of($prev_uuid);
  &inner_read_report($mode);
  if ( $prev_ch eq 'd' && $error_msg =~ /Error: task .*: no matches/ ) {
    # take care of marking last done...
    &inner_read_report('init');
  }
  if ( $current_command eq 'summary' ) {
    &get_num_tasks();
  }
  if ( $mode eq 'refresh' ) {
    &follow_selection($prev_uuid, $prev_offset);
  }
}

#------------------------------------------------------------------
# first_line_of UUID -- the first report line of that task (-1: none)

sub first_line_of {
  my ($uuid) = @_;
  return -1 if ! defined $uuid;
  for my $i (0 .. $#report2uuid) {
    return $i if defined $report2uuid[$i] && $report2uuid[$i] eq $uuid;
  }
  return -1;
}

#------------------------------------------------------------------
# follow_selection UUID OFFSET -- after a re-read, select the same task (and
# the same annotation line of it) wherever it moved to. A task that's gone
# leaves the selection where it was.

sub follow_selection {
  my ($uuid, $offset) = @_;
  my $first = &first_line_of($uuid);
  return if $first < 0;
  my $i = $first + ( $offset > 0 ? $offset : 0 );
  if ( $i > $#report2uuid || ! defined $report2uuid[$i] || $report2uuid[$i] ne $uuid ) {
    $i = $first;
  }
  $task_selected_idx = $i;
  if ( $task_selected_idx < $display_start_idx ) {
    $display_start_idx = $task_selected_idx;
  }
  if ( $task_selected_idx >= $display_start_idx + $REPORT_LINES ) {
    $display_start_idx = $task_selected_idx - $REPORT_LINES + 1;
  }
}

#------------------------------------------------------------------

sub inner_read_report {
  my ($mode) = @_;

  my $report_header_idx = 0;
  my $args;
  my @prev_num_tasks = $num_tasks;
  my @prev_report2taskid = @report2taskid;
  my @prev_report2uuid = @report2uuid;
  my @prev_taskid2report = @taskid2report;
  my @prev_report_tokens = @report_tokens;
  my @prev_report_lines = @report_lines;
  my @prev_report_colors_fg = @report_colors_fg;
  my @prev_report_colors_bg = @report_colors_bg;
  my @prev_report_attrs = @report_attrs;
  my @prev_report_header_tokens = @report_header_tokens;
  my @prev_report_header_attrs = @report_header_attrs;
  $prev_convergence = $convergence;

  $prev_display_start_idx = $display_start_idx;
  $prev_task_selected_idx = $task_selected_idx;
  @report2taskid = ();
  @report2uuid = ();
  @taskid2report = ();
  @report_tokens = ();
  @report_lines = ();
  @report_colors_fg = ();
  @report_colors_bg = ();
  @report_attrs = ();
  @report_header_tokens = ();
  @report_header_attrs = ();
  @project_types = ();
  if ( $mode eq 'init' ) {
    $task_selected_idx = 0;
    $display_start_idx = 0;
  }

  *IN = &task_open({ read => 1, err => 'merge' }, 'stats');
  while(<IN>) {
    chop;
    if ( $_ =~ /^\s*$/ ) { next; }
    $_ =~ s/\x1b.*?m//g;
    if ( $_ =~ /Pending\s+(\d+)/ ) {
      $tasks_pending = $1;
      next;
    }
    if ( $_ =~ /Completed\s+(\d+)/ ) {
      $tasks_completed = $1;
      next;
    }
  }
  close(IN);

  if ( $burndown eq "yes" ) {
    *IN = &task_open({ read => 1, err => 'merge' },
                     "rc.defaultwidth=$REPORT_COLS", "rc.defaultheight=$REPORT_LINES", 'burndown');
    while(<IN>) {
      if ( $_ =~ /Estimated completion: No convergence/ ) {
        $convergence = "no convergence";
        last;
      }
      if ( $_ =~ /Estimated completion: .* \((.*)\)/ ) {
        $convergence = "convergence in $1";
        last;
      }
    }
    close(IN);
    if ( $convergence ne $prev_convergence && $prev_convergence ne '' ) {
      $flash_convergence = 1;
    } else {
      $flash_convergence = 0;
    }
  }

  *IN = &task_open({ read => 1, err => 'merge' }, 'projects');
  while(<IN>) {
    chop;
    if ( $_ =~ /^\s*$/ ) { next; }
    $_ =~ s/\x1b.*?m//g;
    if ( $_ =~ /^\w+ override/ ) { next; }
    if ( $_ =~ /^Project/ ) { next; }
    if ( $_ =~ /^\d+ project/ ) { next; }
    my $p = (split(/\s+/,$_))[0];
    if ( $p eq '(none)' ) { next; }
    push(@project_types, $p);
  }
  close(IN);

  {
    @tag_types=();
    *IN = &task_open({ read => 1, err => 'merge' }, 'tags');
    my $_started = undef;
    while (my $line=<IN>) {
      # list of tasks starts after a line containing "--- -----"
      if ($line =~ /^-+ -+$/) {
        $_started = 1;
        next;
      }
      next unless $_started;

      # save tag in first field of line
      chomp $line;
      last if $line eq '';
      my $t = ( split(/\s+/,$line) )[0];
      push(@tag_types, $t);
    }
    close(IN);
  }

  *IN = &task_open({ read => 1, err => 'null' }, "rc.defaultwidth=$REPORT_COLS", 'rc.defaultheight=0',
                   'rc._forcecolor=on', &split_args($current_command));
  my $i = 0;
  my $prev_id;
  while(<IN>) {
    chop;
    $_ = &decode_utf8($_);
    if ( $_ =~ /^\s*$/ ) { next; }
    # a header's separator (2.6.2's summary prints one, colors or not)
    if ( $_ =~ /^(\x1b.*?m)*[\s-]*-[\s-]*(\x1b.*?m)*$/ ) { next; }
    if ( $_ =~ /^(\d+) tasks?$/ ||
         $_ =~ /^\x1b.*?m(\d+) tasks?\x1b\[0m$/ ||
         $_ =~ /^\d+ tasks?, (\d+) shown$/ ||
         $_ =~ /^\x1b.*?m\d+ tasks?, (\d+) shown\x1b\[0m$/ ) {
      $num_tasks = $1;
      next;
    }
    &parse_report_line($i,$_);
    $_ =~ s/\x1b.*?m//g;
    $report_lines[$i] =  $_;

    # check if this is the header line
    if ( $_ =~ /^ID / ) {
      $report_header_idx = $i;
      $i++;
      next;
    }

    if ( $_ =~ /^\s{0,5}(\d+) / ) {
      $report2taskid[$i] = $1;
      $taskid2report[$1] = $i;
      &audit("inner_read_report: report2taskid[$i]=$1, taskid2report[$1]=$i")
    } else {
      $report2taskid[$i] = $prev_id;
      &audit("inner_read_report: report2taskid[$i]=" . ($prev_id // "none"))
    }
    $prev_id = $report2taskid[$i];
    $i++;
  }
  close(IN);

  if ( $#report_tokens > -1 ) {
    # TODO: this code is quite hard to understand; should probably be rewritten
    #       or at least needs explanation of what is happening here. [BaZo]
    @report_header_tokens = @{ $report_tokens[$report_header_idx] };
    @report_header_attrs = @{ $report_attrs[$report_header_idx] };
    splice(@report_tokens,$report_header_idx,1);
    splice(@report_lines,$report_header_idx,1);
    splice(@report_colors_fg,$report_header_idx,1);
    splice(@report_colors_bg,$report_header_idx,1);
    splice(@report_attrs,$report_header_idx,1);
    splice(@report2taskid,$report_header_idx,1);
    for my $id (0..$#taskid2report) {
      next if ! defined $taskid2report[$id];
      $taskid2report[$id]-- if $taskid2report[$id] > $report_header_idx;
    }
    if ( $task_selected_idx > $#report_tokens ) {
      $task_selected_idx = $#report_tokens;
    }
    # IDs shift when the data changes behind vit (tw-web, a sync): keep each
    # line's UUID, and act on that
    my %uuid = &task_uuids(grep { defined } @report2taskid);
    @report2uuid = map { defined $_ ? $uuid{$_} : undef } @report2taskid;
  } else {
    $error_msg = "Error: task $current_command: no matches";
    $current_command = $prev_command;
    $display_start_idx = $prev_display_start_idx;
    $task_selected_idx = $prev_task_selected_idx;
    @report_header_tokens = @prev_report_header_tokens;
    @report_header_attrs = @prev_report_header_attrs;
    @report_tokens = @prev_report_tokens;
    @report_lines = @prev_report_lines;
    @report_colors_fg = @prev_report_colors_fg;
    @report_colors_bg = @prev_report_colors_bg;
    @report_attrs = @prev_report_attrs;
    @report2taskid = @prev_report2taskid;
    @report2uuid = @prev_report2uuid;
    @taskid2report = @prev_taskid2report;
    $convergence = $prev_convergence;
    return;
  }

}

#------------------------------------------------------------------

sub get_num_tasks {
  $num_tasks = 0;
  *IN = &task_open({ read => 1, err => 'null' }, 'projects');
  while(<IN>) {
    if ( $_ =~ /(\d+) task/ ) {
      $num_tasks = $1;
      last;
    }
  }
  close(IN);
}

#------------------------------------------------------------------

return 1;

