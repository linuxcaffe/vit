# The header shows the context the report really ran with: an override (rc.context=none typed,
# or tw's @_ / @: name, which become one) beats the configured context, as task reports it
source "$(dirname "$0")/lib.sh"
printf 'context.work.read=+work\ncontext.work.write=+work\ncontext.home.read=+home\ncontext=work\n' >> "$TASKRC"
t add alpha +work; t add beta +home
start_vit vt
check "configured context" wait_for "context: work"
prompt : "vt rc.context=none"
check "override: no context" bash -c "! tmux -L $TMUX_SOCK capture-pane -p | grep -q 'context:'"
check "and the view shows all" wait_for beta
prompt : "vt rc.context=home"
check "override: home" wait_for "context: home"
fake_tw
prompt : "@_ vt"
check "tw's @_: no context" bash -c "! tmux -L $TMUX_SOCK capture-pane -p | grep -q 'context:'"
