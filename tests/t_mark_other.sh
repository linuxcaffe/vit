# Esc clears the marks; b and D on an annotation line act on the cursor alone; a re-read drops a
# marked task that left the report
source "$(dirname "$0")/lib.sh"
# no_marks: the header loses its ", N marked" (Esc takes curses' ESC delay, ~1 s)
no_marks() { local n; for n in $(seq 30); do screen | grep -q ', [0-9]* marked' || return 0; sleep 0.1; done; return 1; }
t add alpha; t add beta; t add gamma
t description:beta annotate -- old note
start_vit vt
keys Space Space; settle
check "two marked" wait_for "2 marked"
keys Escape; settle
check "Esc clears" no_marks
keys g g; settle; keys Space; settle                 # alpha marked, cursor on beta
keys b; sleep 0.2; keys y; settle
check "b started beta" test "$(field 'description:beta' '.[0].start // ""')" != ""
check "not alpha" test "$(field 'description:alpha' '.[0].start // ""')" = ""
check "alpha still marked" wait_for "1 marked"
keys j; settle                                       # beta's annotation line
keys D; sleep 0.2; keys y; settle
check "denotated" test "$(field 'description:beta' '.[0].annotations // [] | length')" = 0
check "alpha not deleted" test "$(field 'description:alpha' '.[0].status')" = pending
t description:alpha done
keys C-l; settle
check "a gone task drops out" no_marks
