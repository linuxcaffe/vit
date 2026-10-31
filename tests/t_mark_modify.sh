# A, P, T, m and w act on every marked task
source "$(dirname "$0")/lib.sh"
t add alpha; t add beta; t add gamma
mark2() { keys g g; settle; keys Space; settle; keys j; settle; keys Space; settle; wait_for "2 marked"; }  # alpha, gamma
start_vit vt
mark2; prompt A "shared note"
check "alpha annotated" test "$(field 'description:alpha' '.[0].annotations[0].description')" = "shared note"
check "gamma annotated" test "$(field 'description:gamma' '.[0].annotations[0].description')" = "shared note"
check "beta not" test "$(field 'description:beta' '.[0].annotations // [] | length')" = 0
mark2; keys P; sleep 0.2; keys H; settle
check "priorities" test "$(task rc.verbose=nothing priority:H count 2>/dev/null)" = 2
mark2; prompt T "+x -y"
check "tagged" test "$(task rc.verbose=nothing +x count 2>/dev/null)" = 2
mark2; prompt m "+z"
check "m in the terminal" wait_for "Press return"
keys Enter; settle
check "m on both" test "$(task rc.verbose=nothing +z count 2>/dev/null)" = 2
mark2; prompt w "tomorrow"
check "both waiting" test "$(task rc.verbose=nothing +WAITING count 2>/dev/null)" = 2
check "beta not waiting" test "$(field 'description:beta' '.[0].wait // ""')" = ""
