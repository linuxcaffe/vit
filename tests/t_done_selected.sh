# d on the selected task marks that task done
source "$(dirname "$0")/lib.sh"
t add alpha; t add beta; t add gamma
start_vit vt
select_text beta
keys d; sleep 0.2; keys y; settle
check "beta completed" test "$(field 'description:beta' '.[0].status')" = completed
check "alpha pending" test "$(field 'description:alpha' '.[0].status')" = pending
