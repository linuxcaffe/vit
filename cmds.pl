# Copyright 2012 - 2013, Steve Rader
# Copyright 2013 - 2018, Scott Kostyshak

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
  my $uuid = &selected_uuid() // return;
  my $str = &prompt_str("Annotate: ");
  if ( $str eq '' ) {
    &draw_prompt_line('');
    return;
  }
  # free text: one argument after --, nothing in it is parsed
  my ($es,$result) = &task_exec($uuid, 'annotate', '--', $str);
  if ( $es != 0 ) {
    $error_msg = $result;
    &draw_error_msg();
    return;
  }
  $feedback_msg = "Annotated task $id.";
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
  if ($confirmation) {
    $yes = &prompt_y("Delete current $target? ");
    if ( ! $yes ) {
      &draw_prompt_line('');
      return;
    }
  }
  my ($es,$result) = ($target eq "annotation")
                   ? &task_exec($uuid, 'denotate', '--', $str)
                   : &task_exec($uuid, 'delete');
  if ( $es != 0 ) {
    $error_msg = $result;
    &draw_error_msg();
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
  my $uuid = &selected_uuid() // return;
  if ($confirmation) {
    $yes = &prompt_y("Mark task $id done? ");
    if ( ! $yes ) {
      &draw_prompt_line('');
      return;
    }
  }
  my ($es,$result) = &task_exec($uuid, 'done');
  if ( $es != 0 ) {
    $error_msg = $result;
    &draw_error_msg();
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
  my $id = $report2taskid[$task_selected_idx];
  my $uuid = &selected_uuid() // return;
  &shell_exec([&ui(), $uuid, 'modify', @args],'wait');
  $reread_needed = 1;
}

#------------------------------------------------------------------

sub task_modify_prompt {
  my $id = $report2taskid[$task_selected_idx];
  my $uuid = &selected_uuid() // return;
  my $str = &prompt_str("Modify: ");
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
  my $uuid = &selected_uuid() // return;
  my $prio = &task_info('Priority');
  my @values = @priority_values ? @priority_values : ('H', 'M', 'L');
  my $none = ( grep { lc($_) eq 'n' } @values ) ? '-' : 'n';
  my $p;
  if ( grep { length($_) != 1 } @values ) {
    # a value longer than one key: type it (tab completes)
    $p = &match_priority(&prompt_str("Priority: "), $none, @values);
  } else {
    $p = &match_priority(&prompt_chr("Priority " . join(' ', @values) . " ($none: none): "),
                         $none, @values);
  }
  if ( defined $p && $p ne $prio ) {
    my ($es,$result) = &task_exec($uuid, 'modify', "priority:$p");
    if ( $es != 0 ) {
      $error_msg = $result;
      &draw_error_msg();
      return;
    }
    $feedback_msg = "Modified task $id.";
    &flash_current_task();
    $reread_needed = 1;
  }
  else {
    &draw_prompt_line('');
    return;
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
  my $uuid = &selected_uuid() // return;
  my $p = &prompt_str("Project: ");
  if ( $p eq '' ) {
    &draw_prompt_line('');
    return;
  }
  my $proj = &task_info('Project');
  if ( $p eq $proj ) {
    beep();
    return;
  }
  my ($es,$result) = &task_exec($uuid, 'modify', "project:$p");
  if ( $es != 0 ) {
    $error_msg = $result;
    &draw_error_msg();
    return;
  }
  $feedback_msg = "Modified task $id.";
  &flash_current_task();
  $reread_needed = 1;
}

#------------------------------------------------------------------

sub task_set_wait {
  my $id = $report2taskid[$task_selected_idx];
  my $uuid = &selected_uuid() // return;
  my $w = &prompt_str("Wait: ");
  if ( $w eq '' ) {
    &draw_prompt_line('');
    return;
  }
  my ($es,$result) = &task_exec($uuid, 'modify', "wait:$w");
  if ( $es != 0 ) {
    $error_msg = $result;
    &draw_error_msg();
    return;
  }
  $feedback_msg = "Modified task $id.";
  &flash_current_task();
  $reread_needed = 1;
}

#------------------------------------------------------------------

sub task_set_tag {
  my $id = $report2taskid[$task_selected_idx];
  my $uuid = &selected_uuid() // return;
  my $tags = &prompt_str("Tag: ");
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

    my ($es,$result) = &task_exec($uuid, 'modify', $t);
    if ( $es != 0 ) {
      $error_msg = $result;
      &draw_error_msg();
      return;
    }
  }

  $feedback_msg = "Modified task $id.";
  &flash_current_task();
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
