# A report that prints no ID column (and isn't merely empty) still stops vit: t_empty_start's
# fix mustn't turn a real configuration mistake into an empty screen
source "$(dirname "$0")/lib.sh"
t add -- a task in a project project:home
tmux -L "$TMUX_SOCK" new-session -d -x 120 -y 30 -c "$WORK" \
  "env HOME='$HOME' TASKRC='$TASKRC' XDG_RUNTIME_DIR='$T/run' PATH='$VIT_PATH' '$VIT' projects; echo VIT-EXIT:\$?; sleep 600"
wait_for 'must print an "ID" column' || fail "projects (no ID column) didn't stop vit: $(screen)"
wait_for "VIT-EXIT:1" || fail "exit status: $(screen | tail -2)"
