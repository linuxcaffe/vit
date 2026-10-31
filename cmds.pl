# Copyright 2012 - 2013, Steve Rader
# Copyright 2013 - 2018, Scott Kostyshak

#------------------------------------------------------------------
# Multi-select: %marked holds the marked tasks by UUID. Space toggles the
# cursor's task (every line of it) and moves down. d D m P p T w A act on
# every marked task when there are any (targets), and clear the marks when
# they succeed; every other command acts on the cursor task. Esc clears them.
# V marks every task from $mark_anchor (the last task marked or unmarked) to the
# cursor's; the mouse does the same (mouse.pl).

sub is_marked {
  my ($i) = @_;
  my $uuid = $report2uuid[$i];
  return defined $uuid && $marked{$uuid};
}

# toggle_mark -- mark or unmark the cursor's task, then move to the next task
# (past its annotation lines: a mark is the whole task)
sub toggle_mark {
  my $uuid = &toggle_mark_here() // return;
  my $i = $task_selected_idx;
  $i++ while $i < $#report_tokens && defined $report2uuid[$i] && $report2uuid[$i] eq $uuid;
  if ( defined $report2uuid[$i] && $report2uuid[$i] ne $uuid ) {
    $task_selected_idx = $i;
    if ( $task_selected_idx >= $display_start_idx + $REPORT_LINES ) {
      $display_start_idx = $task_selected_idx - $REPORT_LINES + 1;
    }
  }
  $refresh_needed = 1;
}

# toggle_mark_here -- mark or unmark the cursor's task; its UUID (undef: no task there)
sub toggle_mark_here {
  my $uuid = &selected_uuid() // return undef;
  if ( $marked{$uuid} ) { delete $marked{$uuid}; } else { $marked{$uuid} = 1; }
  $mark_anchor = $uuid;
  $refresh_needed = 1;
  return $uuid;
}

# mark_range -- mark every task from the anchor's line to the cursor's (the
# cursor's alone when the anchor isn't shown); the cursor's becomes the anchor
sub mark_range {
  my $uuid = &selected_uuid() // return;
  my ($from) = grep { defined $report2uuid[$_] && $report2uuid[$_] eq ($mark_anchor // '') }
               0 .. $#report2uuid;
  $from //= $task_selected_idx;
  my ($lo, $hi) = sort { $a <=> $b } ($from, $task_selected_idx);
  $marked{$_} = 1 for grep { defined } @report2uuid[$lo .. $hi];
  $mark_anchor = $uuid;
  $refresh_needed = 1;
}

# task_show_info -- Enter: the task's info; on the summary report, that project's tasks
sub task_show_info {
  if ( $current_command eq 'summary' ) {
    my $p = $report_tokens[$task_selected_idx][0];
    $p =~ s/(.*?)\s+.*/$1/;
    $p =~ s/\(none\)//;
    $current_command = "ls project:$p";
    $reread_needed = 1;
  } else {
    my $uuid = &selected_uuid() // return;
    &shell_exec([&ui(), $uuid, 'information'],'forcewait');
  }
}

# clear_marks -- how many there were
sub clear_marks {
  my $n = scalar(keys %marked);
  %marked = ();
  $mark_anchor = undef;
  return $n;
}

# prune_marks -- after a read: a task that left the report isn't marked any more
sub prune_marks {
  my %shown = map { $_ => 1 } grep { defined } @report2uuid;
  delete @marked{ grep { ! $shown{$_} } keys %marked };
}

# targets -- the tasks a whitelisted command acts on: the marked ones, in
# report order, else the cursor's (undef and an error shown: no task there)
sub targets {
  if ( %marked ) {
    my %seen;
    return grep { defined && $marked{$_} && !$seen{$_}++ } @report2uuid;
  }
  my $uuid = &selected_uuid() // return ();
  return ($uuid);
}

# what targets() acts on, for a prompt: " (3 marked)" or ''
sub marked_label {
  my $n = scalar(keys %marked);
  return $n ? " ($n marked)" : '';
}

#------------------------------------------------------------------

sub prompt_quit {
  my $yes;
  if ($confirmation) {
    $yes = &prompt_y("Quit?");
    if ( ! $yes ) {
      &draw_prompt_line('');
      return;
    }
  }
  &clean_exit()
}

#------------------------------------------------------------------

sub task_add {
  my $str = &prompt_str("Add: ");
  if ( $str eq '' ) {
    &draw_prompt_line('');
    return;
  }
  # a command line: split like a terminal would, attributes parsed by task
  my ($es,$result) = &task_exec('add', &split_args($str));
  if ( $es != 0 ) {
    $error_msg = $result;
    &draw_error_msg();
    return;
  }
  $feedback_msg = $result;
  $reread_needed = 1;
}

#------------------------------------------------------------------

sub task_annotate {
  my $id = $report2taskid[$task_selected_idx];
  my @uuids = &targets() or return;
  my $str = &prompt_str("Annotate" . &marked_label() . ": ");
  if ( $str eq '' ) {
    &draw_prompt_line('');
    return;
  }
  # free text: one argument after --, nothing in it is parsed
  my ($es,$result) = &task_exec(@uuids, 'annotate', '--', $str);
  if ( $es != 0 ) {
    $error_msg = $result;
    &draw_error_msg();
    return;
  }
  my $n = &clear_marks();
  $feedback_msg = $n ? "Annotated $n tasks." : "Annotated task $id.";
  &draw_feedback_msg();
  $reread_needed = 1;
}

#------------------------------------------------------------------

sub task_den_or_del {
  my ($ch, $str, $yes);
  my $id = $report2taskid[$task_selected_idx];
  my $uuid = &selected_uuid() // return;
  for my $t (0 .. $#{ $report_tokens[$task_selected_idx] } ) {
    $str .= "$report_tokens[$task_selected_idx][$t]";
  }
  my $target = ( $str !~ s/^\s*\d+[\/-]\d+[\/-]\d+\s+// )
             ? "task"
             : "annotation";
  $str =~ s/\s+$//;
  # an annotation line: that annotation alone; a task: the marked tasks, if any
  my @uuids = ( $target eq "task" ) ? &targets() : ($uuid);
  return if ! @uuids;
  my $n = ( $target eq "task" ) ? scalar(keys %marked) : 0;
  if ($confirmation) {
    $yes = &prompt_y($n ? "Delete $n marked tasks? " : "Delete current $target? ");
    if ( ! $yes ) {
      &draw_prompt_line('');
      return;
    }
  }
  my ($es,$result) = ($target eq "annotation")
                   ? &task_exec($uuid, 'denotate', '--', $str)
                   : &task_exec(@uuids, 'delete');
  if ( $es != 0 ) {
    $error_msg = $result;
    &draw_error_msg();
    return;
  }
  if ( $n ) {
    &clear_marks();
    $feedback_msg = "Deleted $n tasks.";
    &draw_feedback_msg();
    $reread_needed = 1;
    return;
  }
  $feedback_msg = "Deleted $target.";
  &draw_feedback_msg();
  &flash_current_task();
  $reread_needed = 1;
}

#------------------------------------------------------------------

sub task_start_stop {
  my ($ch, $str, $yes);
  my $id = $report2taskid[$task_selected_idx];
  my $uuid = &selected_uuid() // return;

  my $state = &task_check($uuid, 'active');
  my $prompt = "stop";
  $feedback_msg = "Stopped task";

  if ($state != 0) {
    $prompt = "start";
    $feedback_msg = "Started task";
  }

  if ($confirmation) {
    $yes = &prompt_y("$prompt task?");
    if ( ! $yes ) {
      &draw_prompt_line('');
      return;
    }
  }

  my ($es, $result2) = &task_exec($uuid, $prompt);
  if ( $es != 0 ) {
    $error_msg = $result2;
    &draw_error_msg();
    return;
  }

  &draw_feedback_msg();
  $reread_needed = 1;
}

#------------------------------------------------------------------

sub task_done {
  my ($ch, $str, $yes);
  my $id = $report2taskid[$task_selected_idx];
  my @uuids = &targets() or return;
  my $n = scalar(keys %marked);
  if ($confirmation) {
    $yes = &prompt_y($n ? "Mark $n marked tasks done? " : "Mark task $id done? ");
    if ( ! $yes ) {
      &draw_prompt_line('');
      return;
    }
  }
  my ($es,$result) = &task_exec(@uuids, 'done');
  if ( $es != 0 ) {
    $error_msg = $result;
    &draw_error_msg();
    return;
  }
  if ( $n ) {
    &clear_marks();
    $feedback_msg = "Marked $n tasks done.";
    &draw_feedback_msg();
    $reread_needed = 1;
    return;
  }
  $feedback_msg = "Marked task done.";
  &draw_feedback_msg();
  &flash_current_task();
  $reread_needed = 1;
}

#------------------------------------------------------------------

sub task_filter {
  # the report word wherever it is (tw passes 'vit +home next'); the rest is
  # the filter, kept in front (tw's @_ and @: name work only first). No report
  # word: the default command with a filter.
  my @w = &split_args($current_command);
  my %is_report = map { $_ => 1 } @report_types;
  my ($r) = grep { $is_report{$w[$_]} } 0 .. $#w;
  my $c = defined $r ? $w[$r] : '';
  my $f = &quote_args(map { $w[$_] } grep { ! defined $r || $_ != $r } 0 .. $#w);
  my $str = &prompt_str("Filter: $f");
  if ( $str eq '' ) {
    &draw_prompt_line('');
    $current_command = $c ne '' ? $c : $default_command;
    if ( $f ne '' ) { $reread_needed = 1; }
    return;
  }
  $prev_command = $current_command;
  $current_command = $c ne '' ? "$str $c" : $str;
  $reread_needed = 1;
}

#------------------------------------------------------------------

sub task_modify {
  my @args = @_;
  my @uuids = &targets() or return;
  my $es = &shell_exec([&ui(), @uuids, 'modify', @args],'wait');
  &clear_marks() if &exited_successfully($es);
  $reread_needed = 1;
}

#------------------------------------------------------------------

sub task_modify_prompt {
  my $id = $report2taskid[$task_selected_idx];
  &targets() or return;
  my $str = &prompt_str("Modify" . &marked_label() . ": ");
  if ( $str eq '' ) {
    &draw_prompt_line('');
    return;
  }
  &task_modify(&split_args($str));
  $reread_needed = 1;
}

#------------------------------------------------------------------

sub task_set_priority {
  my $id = $report2taskid[$task_selected_idx];
  my @uuids = &targets() or return;
  my $n = scalar(keys %marked);
  my $prio = $n ? undef : &task_info('Priority');   # several: no "unchanged" to skip
  my @values = @priority_values ? @priority_values : ('H', 'M', 'L');
  my $none = ( grep { lc($_) eq 'n' } @values ) ? '-' : 'n';
  my $p;
  if ( grep { length($_) != 1 } @values ) {
    # a value longer than one key: type it (tab completes)
    $p = &match_priority(&prompt_str("Priority" . &marked_label() . ": "), $none, @values);
  } else {
    $p = &match_priority(&prompt_chr("Priority" . &marked_label() . " " . join(' ', @values) . " ($none: none): "),
                         $none, @values);
  }
  if ( defined $p && ( ! defined $prio || $p ne $prio ) ) {
    my ($es,$result) = &task_exec(@uuids, 'modify', "priority:$p");
    if ( $es != 0 ) {
      $error_msg = $result;
      &draw_error_msg();
      return;
    }
    &modified_feedback($id);
    $reread_needed = 1;
  }
  else {
    &draw_prompt_line('');
    return;
  }
}

#------------------------------------------------------------------
# modified_feedback ID -- after a modify: the marked tasks (marks cleared),
# else the cursor's task (flashed)

sub modified_feedback {
  my ($id) = @_;
  my $n = &clear_marks();
  if ( $n ) {
    $feedback_msg = "Modified $n tasks.";
  } else {
    $feedback_msg = "Modified task $id.";
    &flash_current_task();
  }
}

#------------------------------------------------------------------
# match_priority KEY NONE VALUES -- the value KEY names: exactly, else the one
# value it matches in any case; '' for NONE; undef for no (or several) match

sub match_priority {
  my ($key, $none, @values) = @_;
  return undef if ! defined $key || $key eq '';
  return '' if $key eq $none;
  return $key if grep { $_ eq $key } @values;
  my @ci = grep { lc($_) eq lc($key) } @values;
  return @ci == 1 ? $ci[0] : undef;
}

#------------------------------------------------------------------

sub task_set_project {
  my $id = $report2taskid[$task_selected_idx];
  my @uuids = &targets() or return;
  my $p = &prompt_str("Project" . &marked_label() . ": ");
  if ( $p eq '' ) {
    &draw_prompt_line('');
    return;
  }
  if ( ! %marked && $p eq &task_info('Project') ) {
    beep();
    return;
  }
  my ($es,$result) = &task_exec(@uuids, 'modify', "project:$p");
  if ( $es != 0 ) {
    $error_msg = $result;
    &draw_error_msg();
    return;
  }
  &modified_feedback($id);
  $reread_needed = 1;
}

#------------------------------------------------------------------

sub task_set_wait {
  my $id = $report2taskid[$task_selected_idx];
  my @uuids = &targets() or return;
  my $w = &prompt_str("Wait" . &marked_label() . ": ");
  if ( $w eq '' ) {
    &draw_prompt_line('');
    return;
  }
  my ($es,$result) = &task_exec(@uuids, 'modify', "wait:$w");
  if ( $es != 0 ) {
    $error_msg = $result;
    &draw_error_msg();
    return;
  }
  &modified_feedback($id);
  $reread_needed = 1;
}

#------------------------------------------------------------------

sub task_set_tag {
  my $id = $report2taskid[$task_selected_idx];
  my @uuids = &targets() or return;
  my $tags = &prompt_str("Tag" . &marked_label() . ": ");
  if ( $tags eq '' ) {
    &draw_prompt_line('');
    return;
  }

  # multiple tags can be input separated by a combination of spaces and commas
  # note that this input format precludes inputting a comma as part of a tag
  #
  # keep track of current modifier (default:+) and use it for subsequent tags
  # so "+a b c" means "+a +b +c" and "+a -b c" means "+a -b -c"
  my $mod='+';
  foreach my $t (split(/,?\s+|,/,$tags)) {
    next if $t =~ m/^\s*$/;

    # check if a + or - was specified
    my $fc = substr($t,0,1);
    if ( $fc eq '+'  or  $fc eq '-' ) {
      # if so, save the current modifier
      $mod = $fc;
    } else {
      # if not, add the current modifier
      $t = $mod . $t;
    }

    my ($es,$result) = &task_exec(@uuids, 'modify', $t);
    if ( $es != 0 ) {
      $error_msg = $result;
      &draw_error_msg();
      return;
    }
  }

  &modified_feedback($id);
  $reread_needed = 1;
}

#------------------------------------------------------------------

sub shell_command {
  my $args = $_[0];
  my ($opts, $cmd);
  if ( $args =~ /([^ ]*) (.+)/ ) {
    $opts = $1;
    $cmd = $2;
  }
  else {
    $error_msg = "Empty shell command for ':!'. See help (:h).";
    &draw_error_msg();
    return;
  }

  my $wait = "no-wait";
  foreach my $l ( split //, $opts ) {
    if ( $l eq 'r' ) {
      $reread_needed = 1;
    } elsif ( $l eq 'w' ) {
      $wait = "wait";
    } else {
      $error_msg = "$l is not a valid command option to ':!'. See help (:h).";
      &draw_error_msg();
      return;
    }
  }

  $cmd =~ s/%TASKUUID/$report2uuid[$task_selected_idx] \/\/ ''/ge;
  $cmd =~ s/%TASKID/$report2taskid[$task_selected_idx]/g;
  $cmd =~ s/%TASKARGS/$current_command/g;

  &shell_exec($cmd,"$wait");
}

return 1;
