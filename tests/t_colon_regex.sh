# Bug 4: a : command that isn't a valid regex is an error message, not a crash
source "$(dirname "$0")/lib.sh"
t add alpha
start_vit vt
prompt : "("
check "vit still running" bash -c "! tmux -L $TMUX_SOCK capture-pane -p | grep -q '^VIT-EXIT:'"
