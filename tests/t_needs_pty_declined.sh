# Saying no to the terminal leaves the task unwritten
source "$(dirname "$0")/lib.sh"
hook on-add_pty <<HOOK
#!/bin/sh
IFS= read -r t
[ -n "\$TW_NOINTERACT" ] && { echo 'TW_INTERACTIVE_REQUIRED' >&2; exit 1; }
echo "\$t"
HOOK
t add alpha
start_vit vt
prompt a "needs terminal"
check "asked" wait_for "A hook needs a terminal"
keys n; settle
check "not added" test "$(field 'description.has:terminal' 'length')" = 0
check "said so" wait_for "Not done"
