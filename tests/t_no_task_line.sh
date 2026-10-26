# A task action on a line with no task (the summary view) is an error message, not a crash
source "$(dirname "$0")/lib.sh"
t add alpha project:p
start_vit summary
keys A
check "error shown" wait_for "No task on this line"
check "vit still running" bash -c "! tmux -L $TMUX_SOCK capture-pane -p | grep -q '^VIT-EXIT:'"
keys Escape; keys Enter
check "drill-down to the project" wait_for "task ls project:p"
check "its task listed" wait_for alpha
