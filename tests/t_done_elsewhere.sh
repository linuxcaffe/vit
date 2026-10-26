# Bug 1: a task finished elsewhere: d says so, and finishes nothing else
source "$(dirname "$0")/lib.sh"
t add alpha; t add beta; t add gamma        # IDs 1 2 3
start_vit vt
select_text beta                             # vit holds beta = 2
t description:beta done; t vt                # gamma is 2 now
keys d; sleep 0.2; keys y; settle
check "gamma untouched" test "$(field 'description:gamma' '.[0].status')" = pending
check "alpha untouched" test "$(field 'description:alpha' '.[0].status')" = pending
check "error shown" wait_for "neither pending nor waiting"
