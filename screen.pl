# Copyright 2012 - 2013, Steve Rader
# Copyright 2013 - 2018, Scott Kostyshak

sub draw_screen {
  my ($x,$t,$fg,$bg,$cp,$str);
  my $line = 0;

  $header_win->attron(COLOR_PAIR($COLOR_HEADER));
  &set_attron($header_win,$header_attrs);
  CASE: {
    if ( $current_command eq 'summary' && $num_projects == 1 ) {
      $str = '1 project';
      last CASE;
    }
    if ( $current_command eq 'summary' ) {
      $str = "$num_projects projects";
      last CASE;
    }
    if ( defined $report_total && $num_tasks < $report_total ) {
      $str = "$num_tasks/$report_total tasks";
      last CASE;
    }
    $str = ( $num_tasks == 1 ) ? '1 task' : "$num_tasks tasks";
  }
  my $n_marked = scalar(keys %marked);
  $str .= ", $n_marked marked" if $n_marked;
  &draw_header_line(0,"task $current_command",$str);
  CASE: {
    if ( $current_command eq 'summary' && $num_tasks == 1 ) {
      $str = '1 task';
      last CASE;
    }
    if ( $current_command eq 'summary' ) {
      $str = "$num_tasks tasks";
      last CASE;
    }
    if ( $tasks_completed == 1 ) {
      $str = '1 task completed';
      last CASE;
    }
    $str = "$tasks_completed tasks completed";
  }
  my $lhs = $context_name ne '' ? "context: $context_name" : '';
  $lhs .= '  ' if $lhs ne '' && $convergence ne '';
  &draw_header_line(1,$lhs . $convergence,$str);
  &set_attroff($header_win,$header_attrs);
  $header_win->attroff(COLOR_PAIR($COLOR_HEADER));

  $header_win->attron(COLOR_PAIR($COLOR_REPORT_HEADER));
  $x = 1;
  for $t (0 .. $#report_header_tokens) {
    # each label as task colours it (color.label.sort on the sort columns);
    # the uncoloured gaps between labels in the header's colour, one bar
    my ($lfg, $lbg) = ( $report_header_colors_fg[$t], $report_header_colors_bg[$t] );
    my $coloured = ( $lfg != 999999 || $lbg != 999999 );
    my $lcp = $coloured ? &get_color_pair($lfg,$lbg) : $COLOR_REPORT_HEADER;
    $header_win->attron(COLOR_PAIR($lcp));
    &set_attron($header_win,$report_header_attrs[$t]);
    $header_win->addstr(2,$x,$report_header_tokens[$t]);
    &set_attroff($header_win,$report_header_attrs[$t]);
    $header_win->attroff(COLOR_PAIR($lcp));
    $x += length($report_header_tokens[$t]);
  }
  $header_win->attron(COLOR_PAIR($COLOR_REPORT_HEADER));

  my $repeat_count=($REPORT_COLS - $x + 1);
  if ( $repeat_count < 0 ) {
    # FIXME
    # see commit bd4a905c
    # I triggered this possibility (that is, that $repeat_count is negative)
    # by zooming out and then zooming in very close, on gnome-terminal.
    $repeat_count = 0;
  }
  $str = ' ' x $repeat_count;

  &set_attron($header_win,$report_header_attrs[$#report_header_attrs]);
  $header_win->addstr(2,$x,$str);
  &set_attroff($header_win,$report_header_attrs[$#report_header_attrs]);
  $header_win->attroff(COLOR_PAIR($COLOR_REPORT_HEADER));
  $header_win->refresh();

  #debug("DRAW lines=$REPORT_LINES start=$display_start_idx cur=$task_selected_idx");
  for my $i ($display_start_idx .. ($display_start_idx+$REPORT_LINES-1)) {
    $cp = 0;
    if ( $i > $#report_tokens ) {
      $str = '~' . ' ' x ($COLS-2);
      $report_win->attron(COLOR_PAIR($COLOR_EMPTY_LINE));
      $report_win->attron(A_BOLD);
      $report_win->addstr($line,0,$str);
      $report_win->attroff(A_BOLD);
      $report_win->attroff(COLOR_PAIR($COLOR_EMPTY_LINE));
      $line++;
      next;
    }
    &draw_report_line($i,$line,'with-selection');
    $line++;
  }
  $report_win->refresh();
  &draw_gutter();
  if ( $display_start_idx == 0 ) {
    $cursor_position = 'Top';
  } elsif ( $display_start_idx + $REPORT_LINES >= $#report_tokens + 1 ) {
    $cursor_position = 'Bot';
  } else {
    $cursor_position = int($task_selected_idx/$#report_tokens*100) . '%';
  }
  CASE: {
    if ( $error_msg ne '' ) {
      &draw_error_msg();
      last CASE;
    }
    if ( $feedback_msg ne '' ) {
      &draw_feedback_msg();
      last CASE;
    }
    if ( $input_mode eq 'search' && $search_direction == 1 ) {
      &draw_prompt_line("/$search_pat");
      last CASE;
    }
    if ( $input_mode eq 'search' && $search_direction == 0 ) {
      &draw_prompt_line("?$search_pat");
      last CASE;
    }
    &draw_prompt_line('');
  }
  if ( $flash_convergence ) {
    if ( $burndown eq "yes" ) {
      &flash_convergence();
      $flash_convergence = 0;
      $prev_convergence = $convergence;
    }
  }

}

#------------------------------------------------------------------
# draw_gutter -- screen column 0 beside the report: '*' on each marked line

sub draw_gutter {
  for my $line ( 0 .. $REPORT_LINES - 1 ) {
    my $i = $display_start_idx + $line;
    $gutter_win->addstr($line, 0, ( $i <= $#report_tokens && &is_marked($i) ) ? '*' : ' ');
  }
  $gutter_win->refresh();
}

return 1;

