# Bug 1: IDs renumbered behind vit's back (tw-web, a sync) don't redirect d to another task
source "$(dirname "$0")/lib.sh"
t add alpha; t add beta; t add gamma        # IDs 1 2 3
start_vit vt
select_text gamma                            # vit holds gamma = 3
t 1 done; t vt; t add delta                  # now beta=1 gamma=2 delta=3
keys d; sleep 0.2; keys y; settle
check "gamma completed" test "$(field 'description:gamma' '.[0].status')" = completed
check "delta untouched" test "$(field 'description:delta' '.[0].status')" = pending
