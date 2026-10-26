# @ opens a context prompt: without tw it's task context; the header follows the change
source "$(dirname "$0")/lib.sh"
printf 'context.work.read=+work\ncontext.work.write=+work\n' >> "$TASKRC"
t add alpha +work; t add beta
start_vit vt
keys @; check "task context prompt" wait_for ":!r task context"
type_text "work"; keys Enter; settle
check "context set" test "$(task rc.verbose=nothing _get rc.context 2>/dev/null)" = work
check "header shows it" wait_for "context: work"
check "report follows" bash -c "! tmux -L $TMUX_SOCK capture-pane -p | grep -q beta"
