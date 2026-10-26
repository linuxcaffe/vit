# :h shows the help, wherever vit runs from; :h TOPIC only the matching lines
source "$(dirname "$0")/lib.sh"
t add alpha
start_vit vt
prompt : "h nav"
check "help shown" wait_for "move down one line"
check "only nav lines" bash -c "! tmux -L $TMUX_SOCK capture-pane -p | grep -q 'add a new task'"
keys Escape; type_text ":q"; keys Enter; settle
check "back on the report" wait_for alpha
