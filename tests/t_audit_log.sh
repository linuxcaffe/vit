# -audit logs to $XDG_RUNTIME_DIR/vit/, not into the current folder
source "$(dirname "$0")/lib.sh"
t add alpha
start_vit -audit vt
keys Q; wait_for "VIT-EXIT" || true
check "nothing in the cwd" test ! -e "$WORK/vit_audit.log"
check "log in the runtime dir" grep -q 'EXEC' "$T/run/vit/vit_audit.log"
