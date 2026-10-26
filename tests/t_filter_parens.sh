# Bug 2: a filter with parentheses works
source "$(dirname "$0")/lib.sh"
t add alpha; t add beta; t add gamma
start_vit vt
prompt f "( description:alpha or description:beta )"
check "no error" bash -c "! tmux -L $TMUX_SOCK capture-pane -p | grep -q 'no matches'"
check "alpha shown" wait_for alpha 1
check "gamma hidden" bash -c "! tmux -L $TMUX_SOCK capture-pane -p | grep -q gamma"
