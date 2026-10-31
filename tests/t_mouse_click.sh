# a click selects the line under it; vit has the mouse from the start
source "$(dirname "$0")/lib.sh"
t add alpha; t add beta; t add gamma
start_vit vt
check "mouse reporting on" mouse_on
click 5; settle                          # row 5: the third line, gamma
keys d
check "the clicked task" wait_for "Mark task 3 done?"
keys y; settle
check "gamma completed" test "$(field 'description:gamma' '.[0].status')" = completed
check "alpha pending" test "$(field 'description:alpha' '.[0].status')" = pending
click 3; settle; click 20; settle             # alpha, then below the last task: nothing moves
keys d
check "selection kept" wait_for "Mark task 1 done?"
