# A write tells hooks there's no terminal (TW_NOINTERACT, TW_CLIENT, TW_PREFLIGHT_CMD, TW_SPOOL_DIR)
source "$(dirname "$0")/lib.sh"
hook on-add_env <<HOOK
#!/bin/sh
IFS= read -r t
env | grep '^TW_' | sort > "$T/env.log"
echo "\$t"
HOOK
t add alpha
start_vit vt
prompt a "beta project:x"
check "TW_NOINTERACT=1" grep -qx 'TW_NOINTERACT=1' "$T/env.log"
check "TW_CLIENT=vit" grep -qx 'TW_CLIENT=vit' "$T/env.log"
check "TW_PREFLIGHT_CMD" grep -qx 'TW_PREFLIGHT_CMD=add beta project:x' "$T/env.log"
check "TW_SPOOL_DIR" grep -q '^TW_SPOOL_DIR=/' "$T/env.log"
