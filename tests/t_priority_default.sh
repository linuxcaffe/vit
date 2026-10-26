# Without uda.priority.values, P still offers H M L
source "$(dirname "$0")/lib.sh"
t add alpha
start_vit vt
select_text alpha
keys P; check "values offered" wait_for "H M L"
keys m; settle
check "priority M" test "$(field 'description:alpha' '.[0].priority')" = M
