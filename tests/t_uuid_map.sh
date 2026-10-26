# %TASKUUID in a .vitrc map is the selected task's UUID
source "$(dirname "$0")/lib.sh"
echo "map X=:!w echo %TASKUUID > $T/uuid.txt<Return>" > "$HOME/.vitrc"
t add alpha; t add gamma
start_vit vt
select_text gamma
keys X
check "ran" wait_for "Press return"
keys Enter; settle
check "the UUID" test "$(cat "$T/uuid.txt")" = "$(task rc.verbose=nothing _get 2.uuid 2>/dev/null)"
