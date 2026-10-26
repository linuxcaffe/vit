# P offers the taskrc's priority values, one key each (case-insensitive), n for none
source "$(dirname "$0")/lib.sh"
echo 'uda.priority.values=1,2,3,H,M,L,' >> "$TASKRC"
t add alpha
start_vit vt
select_text alpha
keys P; check "values offered" wait_for "1 2 3 H M L"
keys 2; settle
check "priority 2" test "$(field 'description:alpha' '.[0].priority')" = 2
keys P; sleep 0.2; keys h; settle
check "priority H" test "$(field 'description:alpha' '.[0].priority')" = H
keys P; sleep 0.2; keys x; settle
check "x: unchanged" test "$(field 'description:alpha' '.[0].priority')" = H
keys P; sleep 0.2; keys n; settle
check "n: none" test "$(field 'description:alpha' '.[0].priority // "none"')" = none
