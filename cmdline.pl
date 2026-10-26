# Copyright 2012 - 2013, Steve Rader
# Copyright 2013 - 2018, Scott Kostyshak

sub cmd_line {
  &audit("Inside of cmd_line");
  my ($prompt) = @_;
  my $str = &prompt_str($prompt);
  if ( $str eq '' ) {
    &draw_prompt_line('');
    return;
  }
  if ( $str =~ /^!(.*)/ ) {
    my $rtn = &shell_command($1);
    return;
  }
  if ( $str =~ /^\d+$/ ) {
    if ( ! defined $taskid2report[$str] ) {
       $error_msg = "Error: task number $str not found";
       &draw_error_msg();
       return;
    }
    $task_selected_idx = $taskid2report[$str] - 1;
    if ( $display_start_idx + $REPORT_LINES < $task_selected_idx ) {
      $display_start_idx = int($task_selected_idx - $REPORT_LINES + ($REPORT_LINES / 2));
    }
    if ( $display_start_idx > $task_selected_idx ) {
      $display_start_idx = int($task_selected_idx - $REPORT_LINES + ($REPORT_LINES / 2));
      if ( $display_start_idx < 0 ) {
        $display_start_idx = 0;
      } elsif ( $display_start_idx > $task_selected_idx) {
        $display_start_idx = $task_selected_idx;
      }
    }
    &draw_screen();
    return;
  }
  if ( $str =~ /^s\/(.*?)\/(.*)\/$/ || $str =~ /^%s\/(.*?)\/(.*)\/$/ ) {
    my ($old,$new) = ($1,$2);
    my $rtn = &task_modify("/$old/$new/");
    $reread_needed = 1;
    return;
  }
  if ( $str eq 'help' || $str eq 'h' ) {
    &show_help('');
    return;
  }
  if ( $str =~ /^help (.*)/ || $str =~ /^h (.*)/ ) {
    &show_help($1);
    return;
  }
  if ( $str eq 'q' ) {
    &clean_exit();
  }
  if ( grep { $_ eq $str } @report_types ) {
    $prev_command = $current_command;
    $current_command = $str;
    &read_report('init');
    &draw_screen();
    return;
  }
  if ( $str =~ /^(.*?) .*/ ) {
    my $s = $1;
    if ( grep { index($_, $s) == 0 } @report_types ) {
      $prev_command = $current_command;
      $current_command = $str;
      &read_report('init');
      &draw_screen();
      return;
    }
  }
  $error_msg = "$str: command not found";
  &draw_error_msg();
  return;
}

#------------------------------------------------------------------
# show_help TEXT -- the help (after __DATA__ in the built vit), only the lines
# containing TEXT (literally, any case) when it's given, in view (vim) or less

sub show_help {
  my ($p) = @_;
  if ( ! @help_lines ) {
    @help_lines = <DATA>;
  }
  my $tmp = File::Temp->new(TEMPLATE => 'vit-help.XXXXXX', TMPDIR => 1);
  print $tmp "\n";
  for my $line ( @help_lines ) {
    print $tmp $line if $p eq '' || index(lc($line), lc($p)) >= 0;
  }
  print $tmp "\n";
  close($tmp);
  my $viewer = ( grep { -x "$_/view" } split(/:/, $ENV{PATH} || '') ) ? 'view' : 'less';
  &shell_exec([$viewer, $tmp->filename],'no-wait');
}

return 1;
