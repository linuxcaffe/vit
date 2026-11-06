# a :! map using %TASKUUID on a completed task's line (ID -), or one vit can't pair with a UUID, never
# runs: `task  start` is task's "no filter, will modify all" prompt, and `task UUID start` reopens it
source "$(dirname "$0")/lib.sh"
cat > "$HOME/.vitrc" <<'RC'
map +=:!r task %TASKUUID start<Return>
map ^=:!r task %TASKID start<Return>
RC
t add beta; t description:beta done; t add alpha
start_vit completed
select_text beta
keys +
check "refused on the screen" wait_for "completed or deleted"
check "no prompt from task" bash -c "! tmux -L '$TMUX_SOCK' capture-pane -p | grep -qE 'no filter|yes/no'"
check "alpha not started" test "$(field 'description:alpha' '.[0].start // ""')" = ""
select_text beta
keys ^
check "%TASKID refused too" wait_for "completed or deleted"
check "vit still up" bash -c "! tmux -L '$TMUX_SOCK' capture-pane -p | grep -q VIT-EXIT"
