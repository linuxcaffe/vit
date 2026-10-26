# Bug 1: = shows the selected task, even after IDs were renumbered elsewhere
source "$(dirname "$0")/lib.sh"
t add alpha; t add beta; t add gamma
start_vit vt
select_text gamma
t 1 done; t vt; t add delta                  # gamma 2, delta 3
keys =
check "info shown" wait_for "Press return"
check "it's gamma" bash -c "tmux -L $TMUX_SOCK capture-pane -p | grep -q '^Description *gamma'"
keys Enter
