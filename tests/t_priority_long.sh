# Priority values longer than one key are typed, with tab completion
source "$(dirname "$0")/lib.sh"
echo 'uda.priority.values=low,mid,high,' >> "$TASKRC"
t add alpha
start_vit vt
select_text alpha
prompt P "mid"
check "priority mid" test "$(field 'description:alpha' '.[0].priority')" = mid
keys P; sleep 0.2; type_text "hi"; keys Tab; sleep 0.2; keys Enter; settle
check "tab-completed high" test "$(field 'description:alpha' '.[0].priority')" = high
