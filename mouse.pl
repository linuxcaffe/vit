#------------------------------------------------------------------
# The mouse (on unless the vitrc says "set mouse=no"): a click selects the line
# under it, a double-click shows the task's info (Enter), ctrl-click or a right
# click marks or unmarks the task, shift-click marks a range (V), the wheel
# moves the selection three lines. Clicks inside a prompt are dropped
# (prompt_getch). ncurses gives the mouse back to the terminal while vit is
# suspended (shell_exec) and takes it again on return.

# init_mouse -- from init_curses
sub init_mouse {
  return if ! $mouse;
  my $old = 0;
  mousemask(BUTTON1_CLICKED | BUTTON1_DOUBLE_CLICKED | BUTTON3_CLICKED
            | BUTTON4_PRESSED | &button5_pressed(), $old);
}

# Curses.pm has no BUTTON5_PRESSED: one button's bits on from button 4's
# (5 bits a button in ncurses 6's mouse ABI, 6 in the old one)
sub button5_pressed {
  return BUTTON4_PRESSED * ( BUTTON2_PRESSED / BUTTON1_PRESSED );
}

# mouse_event -- a KEY_MOUSE from the report window's getch
sub mouse_event {
  my $ev = '';
  return if getmouse($ev) == ERR;
  my (undef, $x, $y, undef, $b) = unpack('s x2 i3 L', $ev);
  &audit("Mouse: x=$x y=$y buttons=" . sprintf('%#x', $b));
  if ( $b & BUTTON4_PRESSED ) { &move_selection(-3); return; }
  if ( $b & &button5_pressed() ) { &move_selection(3); return; }
  my ($top, $left);
  $report_win->getbegyx($top, $left);
  my $line = $y - $top;
  return if $line < 0 || $line >= $REPORT_LINES;
  my $i = $display_start_idx + $line;
  return if $i > $#report_tokens;
  $task_selected_idx = $i;
  $refresh_needed = 1;
  if ( $b & BUTTON1_DOUBLE_CLICKED ) {
    &task_show_info();
  } elsif ( $b & BUTTON3_CLICKED || ( $b & BUTTON1_CLICKED && $b & BUTTON_CTRL ) ) {
    &toggle_mark_here();
  } elsif ( $b & BUTTON1_CLICKED && $b & BUTTON_SHIFT ) {
    &mark_range();
  }
}

# move_selection N -- N lines down (up when negative), stopping at the ends;
# the screen scrolls to keep the selection on it
sub move_selection {
  my ($n) = @_;
  return if $#report_tokens < 0;
  my $i = $task_selected_idx + $n;
  $i = 0 if $i < 0;
  $i = $#report_tokens if $i > $#report_tokens;
  $task_selected_idx = $i;
  if ( $i < $display_start_idx ) {
    $display_start_idx = $i;
  } elsif ( $i >= $display_start_idx + $REPORT_LINES ) {
    $display_start_idx = $i - $REPORT_LINES + 1;
  }
  $refresh_needed = 1;
}

return 1;
