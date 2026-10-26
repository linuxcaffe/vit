# s runs gittw sync in the terminal, on vit's own data folder (TW_TASK_DIR from data.location)
source "$(dirname "$0")/lib.sh"
fake_cmd gittw <<FAKE
#!/bin/sh
echo "args=\$* dir=\$TW_TASK_DIR" > "$T/gittw.log"
echo FAKE-GITTW-RAN
FAKE
t add alpha
start_vit vt
keys s
check "ran" wait_for "FAKE-GITTW-RAN"
keys Enter; settle
check "sync, on the scratch data" test "$(cat "$T/gittw.log")" = "args=sync dir=$DATA"
