# Without gittw, s runs task sync (taskd) as before
source "$(dirname "$0")/lib.sh"
t add alpha
start_vit vt
keys s
check "task sync ran" wait_for "Taskserver is not configured"
keys Enter
