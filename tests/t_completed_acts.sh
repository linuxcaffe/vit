# a completed task's line (no ID) has its UUID: m A e Enter D act on that very task; d b and maps refuse
source "$(dirname "$0")/lib.sh"
cat > "$HOME/.vitrc" <<'RC'
map +=:!r task %TASKUUID start<Return>
RC
t add alpha; t add beta; t add gamma; t add live
t description:alpha done; t description:beta done; t description:gamma done
st() { field "description:$1" ".[0].$2 // \"\""; }
start_vit completed
select_text beta
prompt A "a note"
check "says which" wait_for "Annotated task"
check "annotated beta" test "$(st beta 'annotations[0].description')" = "a note"
check "alpha untouched" test "$(st alpha annotations)" = ""
settle
select_text beta
keys m; sleep 0.2; type_text "project:home"; keys Enter; settle; keys Enter; settle
check "modified beta" test "$(st beta project)" = home
check "gamma untouched" test "$(st gamma project)" = ""
select_text "a note"
keys m; sleep 0.2; type_text "priority:H"; keys Enter; settle; keys Enter; settle
check "its annotation line is beta too" test "$(st beta priority)" = H
select_text gamma
keys d
check "d refuses" wait_for "completed or deleted"
keys b
check "b refuses" wait_for "completed or deleted"
keys +
check "a map refuses" wait_for "completed or deleted"
check "gamma not started" test "$(st gamma start)" = ""
check "gamma still completed" test "$(st gamma status)" = completed
keys D; sleep 0.2; keys y; settle
check "D deletes gamma" test "$(st gamma status)" = deleted
check "alpha still completed" test "$(st alpha status)" = completed
check "live still pending" test "$(st live status)" = pending
