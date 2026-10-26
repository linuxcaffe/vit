# Started as tw passes it (filter before report: vit +x vt), f edits the filter, not the report
source "$(dirname "$0")/lib.sh"
t add alpha +x; t add beta +x; t add gamma
start_vit +x vt
check "filtered" bash -c "! tmux -L $TMUX_SOCK capture-pane -p | grep -q gamma"
keys f; check "the filter is offered" wait_for "Filter: +x"
keys C-u; type_text "+x description:beta"; keys Enter; settle
check "beta shown" wait_for beta
check "alpha gone" bash -c "! tmux -L $TMUX_SOCK capture-pane -p | grep -q alpha"
