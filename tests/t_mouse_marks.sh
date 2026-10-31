# ctrl-click and right-click toggle a task's mark; shift-click and V mark a range from the last
# task marked or unmarked (or from the cursor, with none)
source "$(dirname "$0")/lib.sh"
t add alpha; t add beta; t add delta; t add epsilon; t add gamma   # vt: by description, rows 3-7
start_vit vt
right_click 7; settle                    # right: gamma
check "right-click marks" wait_for "5 tasks shown, 1 marked"
right_click 7; settle
check "and unmarks" wait_for "5 tasks shown"
click 3 16; settle                       # ctrl: alpha
check "ctrl-click marks" wait_for "5 tasks shown, 1 marked"
click 6 4; settle                        # shift: alpha to epsilon
check "a range" wait_for "5 tasks shown, 4 marked"
check "gamma not in it" test "$(screen | grep -c '^\*.*gamma')" = 0
keys Escape; settle
check "cleared" wait_for "5 tasks shown"
click 4; settle; keys Space; settle      # beta marked, cursor on delta
keys j j; settle                         # cursor on gamma
keys V; settle
check "V: beta to gamma" wait_for "5 tasks shown, 4 marked"
check "alpha not in it" test "$(screen | grep -c '^\*.*alpha')" = 0
keys d
check "acts on the range" wait_for "Mark 4 marked tasks done?"
keys y; settle
check "alpha pending" test "$(field 'description:alpha' '.[0].status')" = pending
check "gamma done" test "$(field 'description:gamma' '.[0].status')" = completed
keys V; settle                           # no mark yet: V marks the cursor's task
check "V alone" wait_for "1 task shown, 1 marked"
