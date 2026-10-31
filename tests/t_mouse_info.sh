# a double-click shows the task's info (like Enter), with the mouse given back to the terminal meanwhile
source "$(dirname "$0")/lib.sh"
t add alpha; t add beta
start_vit vt
double_click 4; settle
check "info shown" wait_for "Press return"
check "beta's info" sh -c "tmux -L $TMUX_SOCK capture-pane -p | grep -q 'Description *beta'"
check "terminal has the mouse" test "$(tmux -L "$TMUX_SOCK" display -p "#{mouse_any_flag}")" = 0
keys Enter; settle
check "vit has it again" mouse_on
