# The header shows the active context (task's rc.context); none, nothing
source "$(dirname "$0")/lib.sh"
printf 'context.work.read=+work\ncontext.work.write=+work\n' >> "$TASKRC"
t add alpha +work; t add beta
start_vit vt
check "no context, no label" bash -c "! tmux -L $TMUX_SOCK capture-pane -p | grep -q 'context:'"
keys Q; wait_for VIT-EXIT
tmux -L "$TMUX_SOCK" kill-server
echo 'context=work' >> "$TASKRC"
start_vit vt
check "context shown" wait_for "context: work"
check "and applied" bash -c "! tmux -L $TMUX_SOCK capture-pane -p | grep -q beta"
