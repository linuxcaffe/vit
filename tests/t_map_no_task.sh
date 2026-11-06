# a :! map using %TASKUUID on a line with no task (a completed task, ID -) never reaches task with
# an empty filter: `task  start` is task's "no filter, will modify all" prompt, and worse if answered
source "$(dirname "$0")/lib.sh"
cat > "$HOME/.vitrc" <<'RC'
map +=:!r task %TASKUUID start<Return>
map ^=:!r task %TASKID start<Return>
RC
t add beta; t description:beta done; t add alpha
start_vit completed
select_text beta
keys +
check "refused on the screen" wait_for "No task on this line"
check "no prompt from task" bash -c "! tmux -L '$TMUX_SOCK' capture-pane -p | grep -qE 'no filter|yes/no'"
check "alpha not started" test "$(field 'description:alpha' '.[0].start // ""')" = ""
select_text beta
keys ^
check "%TASKID refused too" wait_for "No task on this line"
check "vit still up" bash -c "! tmux -L '$TMUX_SOCK' capture-pane -p | grep -q VIT-EXIT"
