# vit starts on a report, lists its tasks and quits cleanly with Q
source "$(dirname "$0")/lib.sh"
t add alpha; t add beta
start_vit vt
check "alpha listed" wait_for alpha
check "beta listed" wait_for beta
check "count in header" wait_for "2 tasks shown"
keys Q
check "exit status 0" wait_for "VIT-EXIT:0"
