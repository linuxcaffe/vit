# a filter set with f stays through report changes (:REPORT) until f clears it
source "$(dirname "$0")/lib.sh"
cat >> "$TASKRC" <<RC
report.vt2.columns=id,description
report.vt2.labels=ID,Desc
report.vt2.sort=description+
report.vt2.filter=status:pending
RC
t add alpha +x; t add beta
start_vit vt
prompt f "+x"
prompt : "vt2"
check "on vt2" wait_for "task vt2"
check "alpha listed" wait_for alpha
check "beta still filtered out" bash -c "! tmux -L $TMUX_SOCK capture-pane -p | grep -q beta"
check "filter still shown" wait_for "filter: +x"
keys f; sleep 0.2; keys BSpace BSpace Enter; settle
check "cleared: beta back" wait_for beta
check "still on vt2" wait_for "task vt2"
check "filter label gone" bash -c "! tmux -L $TMUX_SOCK capture-pane -p | grep -q 'filter:'"
