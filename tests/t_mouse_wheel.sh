# the wheel moves the selection three lines a notch, and stops at the ends
source "$(dirname "$0")/lib.sh"
for i in 01 02 03 04 05 06 07 08 09 10; do t add task$i; done
start_vit vt
wheel down; settle; wheel down; settle    # line 7
keys d
check "down six" wait_for "Mark task 7 done?"
keys n; settle
wheel up; settle                          # line 4
keys d
check "up three" wait_for "Mark task 4 done?"
keys n; settle
wheel down; wheel down; wheel down; wheel down; settle    # past the end: the last line
keys d
check "stops at the last" wait_for "Mark task 10 done?"
keys n; settle
