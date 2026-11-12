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
  &prune_marks();
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
  my %prev_no_id_uuid = %no_id_uuid;
  my @prev_taskid2report = @taskid2report;
  my @prev_report_tokens = @report_tokens;
  my @prev_report_lines = @report_lines;
  my @prev_report_colors_fg = @report_colors_fg;
  my @prev_report_colors_bg = @report_colors_bg;
  my @prev_report_attrs = @report_attrs;
  my @prev_report_header_tokens = @report_header_tokens;
  my @prev_report_header_attrs = @report_header_attrs;
  my @prev_report_header_colors_fg = @report_header_colors_fg;
  my @prev_report_header_colors_bg = @report_header_colors_bg;
  $prev_convergence = $convergence;

  $prev_display_start_idx = $display_start_idx;
  $prev_task_selected_idx = $task_selected_idx;
  @report2taskid = ();
  @report2uuid = ();
  %no_id_uuid = ();
  @taskid2report = ();
  @report_tokens = ();
  @report_lines = ();
  @report_colors_fg = ();
  @report_colors_bg = ();
  @report_attrs = ();
  @report_header_tokens = ();
  @report_header_attrs = ();
  @report_header_colors_fg = ();
  @report_header_colors_bg = ();
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

  # stderr kept aside: task says there when the context was overridden
  # (rc.context=… typed, or tw's @_ and @: name), which the header shows
  my $errf = File::Temp->new(TEMPLATE => 'vit-err.XXXXXX', TMPDIR => 1);
  *IN = &task_open({ read => 1, ui => 1, errfile => $errf->filename }, &command_args(),
                   "rc.defaultwidth=$REPORT_COLS", 'rc.defaultheight=0', 'rc._forcecolor=on',
                   $nice ? ( 'rc.dateformat.report=' . &nice_dateformat() ) : ());
  my @lines = map { chop; &decode_utf8($_) } <IN>;
  close(IN);
  @lines = &nice_lines(@lines) if $nice;
  my $i = 0;
  my $prev_id;
  my @rows;      # one per task in the report: [ ID or '-', its line's text ]
  my @line2row;  # each line's task, as an index into @rows
  my ($id_col, $id_width);   # the ID column, from the header (first, or after Active, ...)
  for (@lines) {
    if ( $_ =~ /^\s*$/ ) { next; }
    # a header's separator (2.6.2's summary prints one, colors or not)
    if ( $_ =~ /^(\x1b\[[0-9;]*m)*[\s-]*-[\s-]*(\x1b\[[0-9;]*m)*$/ ) { next; }
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

    # check if this is the header line: its ID label says where the IDs are
    if ( ! defined $id_col && ! @rows && $_ =~ /^(.*?)(?<!\S)ID(?!\S)/ ) {
      $id_col = length($1);
      $id_width = ( substr($_, $id_col) =~ /^ID\s+/ ) ? $+[0] : undef;
      $report_header_idx = $i;
      $i++;
      next;
    }

    my $row_id = &line_id($_, $id_col, $id_width);
    # ID -: a completed or deleted task, not the task on the line above
    $prev_id = undef if defined $row_id && $row_id eq '-';
    push @rows, [ $row_id, $_ ] if defined $row_id;
    $line2row[$i] = $#rows if @rows;
    if ( defined $row_id && $row_id ne '-' ) {
      $report2taskid[$i] = $row_id;
      $taskid2report[$row_id] = $i;
      &audit("inner_read_report: report2taskid[$i]=$row_id, taskid2report[$row_id]=$i")
    } else {
      $report2taskid[$i] = $prev_id;
      &audit("inner_read_report: report2taskid[$i]=" . ($prev_id // "none"))
    }
    $prev_id = $report2taskid[$i];
    $i++;
  }

  $report_total = &report_total();

  # IDs shift when the data changes behind vit (tw-web, a sync): keep each
  # line's UUID, and act on that. The context comes in the same call.
  my ($context, %uuid) = &task_uuids(grep { defined } @report2taskid);
  $context_name = $context;
  if ( open(my $err, '<', $errf->filename) ) {
    while ( my $line = <$err> ) {
      $line =~ s/\x1b.*?m//g;   # the report runs with color on
      if ( $line =~ /^Configuration override rc\.context[:=](\S*)/ ) {
        $context_name = ( $1 eq 'none' ) ? '' : $1;
      }
    }
    close($err);
  }

  if ( $#report_tokens > -1 ) {
    # TODO: this code is quite hard to understand; should probably be rewritten
    #       or at least needs explanation of what is happening here. [BaZo]
    @report_header_tokens = @{ $report_tokens[$report_header_idx] };
    @report_header_attrs = @{ $report_attrs[$report_header_idx] };
    @report_header_colors_fg = @{ $report_colors_fg[$report_header_idx] };
    @report_header_colors_bg = @{ $report_colors_bg[$report_header_idx] };
    splice(@report_tokens,$report_header_idx,1);
    splice(@report_lines,$report_header_idx,1);
    splice(@report_colors_fg,$report_header_idx,1);
    splice(@report_colors_bg,$report_header_idx,1);
    splice(@report_attrs,$report_header_idx,1);
    splice(@report2taskid,$report_header_idx,1);
    splice(@line2row,$report_header_idx,1) if $report_header_idx <= $#line2row;
    for my $id (0..$#taskid2report) {
      next if ! defined $taskid2report[$id];
      $taskid2report[$id]-- if $taskid2report[$id] > $report_header_idx;
    }
    if ( $task_selected_idx > $#report_tokens ) {
      $task_selected_idx = $#report_tokens;
    }
    @report2uuid = map { defined $_ ? $uuid{$_} : undef } @report2taskid;
    # A line with no ID (a completed or deleted task) has no ID to ask with
    if ( grep { $_->[0] eq '-' } @rows ) {
      my @row_uuid = &no_id_uuids(\@rows, join('', @report_header_tokens) =~ /\bUUID\b/);
      for my $l ( 0 .. $#report2taskid ) {
        next if defined $report2taskid[$l] || ! defined $line2row[$l];
        my $u = $row_uuid[ $line2row[$l] ] // next;
        $report2uuid[$l] = $u;
        $no_id_uuid{$u} = 1;
      }
    }
  } else {
    $error_msg = "Error: task " . &quote_args(&command_args()) . ": no matches";
    $current_command = $prev_command;
    $filter = $prev_filter;
    $display_start_idx = $prev_display_start_idx;
    $task_selected_idx = $prev_task_selected_idx;
    @report_header_tokens = @prev_report_header_tokens;
    @report_header_attrs = @prev_report_header_attrs;
    @report_header_colors_fg = @prev_report_header_colors_fg;
    @report_header_colors_bg = @prev_report_header_colors_bg;
    @report_tokens = @prev_report_tokens;
    @report_lines = @prev_report_lines;
    @report_colors_fg = @prev_report_colors_fg;
    @report_colors_bg = @prev_report_colors_bg;
    @report_attrs = @prev_report_attrs;
    @report2taskid = @prev_report2taskid;
    @report2uuid = @prev_report2uuid;
    %no_id_uuid = %prev_no_id_uuid;
    @taskid2report = @prev_taskid2report;
    $convergence = $prev_convergence;
    return;
  }
  $prev_filter = $filter;
}

#------------------------------------------------------------------
# report_total -- how many tasks the current report holds with no context and
# no typed filter: the bottom of the header's 34/92. undef if the command names
# no report (the header then gives the plain count).

sub report_total {
  my $report = &report_name() // return undef;
  my $filter = &task_get("rc.report.$report.filter");
  my @words = grep { ! /^limit:/ } &split_args($filter);
  my $fh = &task_open({ read => 1 }, 'rc.context=none', ( @words ? ( '(', @words, ')' ) : () ), 'count');
  my $total;
  while ( my $line = <$fh> ) {
    $total = $1 if $line =~ /^(\d+)\s*$/;
  }
  &task_close($fh);
  return $total;
}

#------------------------------------------------------------------
# line_id LINE, COL, WIDTH -- the ID (or '-': no ID) in a report line's ID
# column, undef if the cell is blank (an annotation, a wrapped line). With no
# ID label in the header: a number or '-' at the start of the line.

sub line_id {
  my ($line, $col, $width) = @_;
  if ( ! defined $col ) {
    return $line =~ /^\s{0,5}(\d+|-) / ? $1 : undef;
  }
  return undef if length($line) <= $col;
  my $cell = defined $width ? substr($line, $col, $width) : substr($line, $col);
  return $cell =~ /^\s*(\d+|-)\s*$/ ? $1 : undef;
}

#------------------------------------------------------------------
# command_args -- what a report read runs: f's filter, then the command. tw's
# @_ and @: name work only first, so a command's leading @ words go in front.

sub command_args {
  my @c = &split_args($current_command);
  my @at;
  push @at, shift @c while @c && $c[0] =~ /^@/;
  return (@at, &split_args($filter), @c);
}

#------------------------------------------------------------------
# report_name -- the report the current command names, or undef

sub report_name {
  my %is_report = map { $_ => 1 } @report_types;
  my ($report) = grep { $is_report{$_} } &split_args($current_command);
  return $report;
}

#------------------------------------------------------------------
# no_id_uuids ROWS, HAS_UUID_COLUMN -- for each report row with no ID, its UUID
# (undef elsewhere). The same command again with only the ID and UUID columns
# lists the same tasks in the same order, so the rows pair off by position; any
# doubt about that (the data changed between the calls, an unusual report) and
# there are no UUIDs: such a line then refuses, it never acts on another task.

sub no_id_uuids {
  my ($rows, $has_uuid_column) = @_;
  my $report = &report_name() // return ();
  my $fh = &task_open({ read => 1, ui => 1 }, &command_args(),
                      "rc.report.$report.columns=id,uuid", "rc.report.$report.labels=ID,UUID",
                      'rc.defaultwidth=200', 'rc.defaultheight=0', 'rc._forcecolor=off', 'rc.verbose=nothing');
  my @listed;
  while ( my $line = <$fh> ) {
    push @listed, [ $1, $2 ] if $line =~ /^\s*(\d+|-)\s+([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\s*$/;
  }
  &task_close($fh);
  return () if @listed != @$rows;
  my @uuids;
  for my $r ( 0 .. $#listed ) {
    return () if $listed[$r][0] ne $rows->[$r][0];
    my $short = substr($listed[$r][1], 0, 8);
    return () if $has_uuid_column && index($rows->[$r][1], $short) < 0;
    $uuids[$r] = $listed[$r][1] if $listed[$r][0] eq '-';
  }
  return @uuids;
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

