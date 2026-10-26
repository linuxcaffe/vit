# :N for a task no longer in the report says so, instead of jumping by an old table
source "$(dirname "$0")/lib.sh"
t add alpha; t add beta; t add gamma
start_vit vt
prompt f "description:alpha"
prompt : "3"
check "not found" wait_for "task number 3 not found"
check "vit still running" bash -c "! tmux -L $TMUX_SOCK capture-pane -p | grep -q '^VIT-EXIT:'"
