# Bug 4: :h with text that isn't a valid regex shows the help (matched literally), no crash
source "$(dirname "$0")/lib.sh"
t add alpha
start_vit vt
prompt : "h ("
sleep 0.5; keys Escape; type_text ":q"; keys Enter; settle
check "vit still running" bash -c "! tmux -L $TMUX_SOCK capture-pane -p | grep -q '^VIT-EXIT:'"
check "back on the report" wait_for alpha
