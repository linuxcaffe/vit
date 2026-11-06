# the ID is found under the header's ID label, wherever it is: an Active column before it (empty until
# a task starts) doesn't lose the task, and digits in an annotation line aren't taken for an ID
source "$(dirname "$0")/lib.sh"
cat >> "$TASKRC" <<'RC'
report.va.columns=start.age,id,description
report.va.labels=Active,ID,Description
report.va.sort=description+
report.va.filter=status:pending
RC
cat > "$HOME/.vitrc" <<'RC'
map +=:!r task %TASKUUID start<Return>
map -=:!r task %TASKUUID stop<Return>
RC
st() { field "description:$1" '.[0].start // ""'; }
# until TEST ARGS... -- poll: a map runs in the background of the key loop
until_() { local n=0; until "$@"; do n=$((n + 1)); [ $n -gt 50 ] && return 1; sleep 0.1; done; }
started() { test -n "$(st "$1")"; }
stopped() { test -z "$(st "$1")"; }
t add alpha; t add beta; t add gamma
t add older; t description:older modify start:now-3mo
start_vit va
select_text alpha
keys +
check "alpha started" until_ started alpha
settle; select_text alpha
keys -
check "alpha stopped: its row now begins with the Active cell" until_ stopped alpha
settle; select_text beta
keys +
check "beta started" until_ started beta
settle; select_text beta
keys -
check "beta stopped too" until_ stopped beta
settle; select_text older
keys -
check "a row with a wide Active cell" until_ stopped older
settle
t description:gamma start
keys :; sleep 0.2; type_text "va"; keys Enter; settle
select_text gamma
prompt A "5 apples"
check "annotated" test "$(field 'description:gamma' '.[0].annotations[0].description')" = "5 apples"
select_text "5 apples"
prompt A "second"
check "the annotation line is gamma's" test "$(field 'description:gamma' '.[0].annotations | length')" = 2
keys :; sleep 0.2; type_text "va"; keys Enter; settle
