# More marked tasks than rc.bulk (3): vit has asked, so task doesn't ask again (it would answer no)
source "$(dirname "$0")/lib.sh"
# no_marks: the header loses its ", N marked" (Esc takes curses' ESC delay, ~1 s)
no_marks() { local n; for n in $(seq 30); do screen | grep -q ', [0-9]* marked' || return 0; sleep 0.1; done; return 1; }
for x in a1 a2 a3 a4 a5; do t add $x; done
start_vit vt
keys Space Space Space Space Space; settle
check "five marked" wait_for "5 marked"
prompt p "home"
check "all five moved" test "$(task rc.verbose=nothing project:home count 2>/dev/null)" = 5
check "marks cleared after the command" no_marks
