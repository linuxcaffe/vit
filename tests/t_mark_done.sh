# Space marks the task and moves down; d then acts on every marked task, asks first, and clears the marks
source "$(dirname "$0")/lib.sh"
t add alpha; t add beta; t add gamma
start_vit vt
keys Space; settle                      # alpha marked, cursor on beta
keys j; settle; keys Space; settle      # gamma marked
check "the header counts them" wait_for "3 tasks shown, 2 marked"
check "a gutter mark" test "$(screen | grep -c '^\*')" = 2
keys d
check "asks about the marked" wait_for "Mark 2 marked tasks done?"
keys y; settle
check "alpha completed" test "$(field 'description:alpha' '.[0].status')" = completed
check "gamma completed" test "$(field 'description:gamma' '.[0].status')" = completed
check "beta pending" test "$(field 'description:beta' '.[0].status')" = pending
check "marks cleared" wait_for "1 task shown"
check "no mark left" test "$(screen | grep -c '^\*')" = 0
