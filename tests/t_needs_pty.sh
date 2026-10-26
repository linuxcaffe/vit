# A hook that answers tw_needs_pty gets the command again in the terminal, with TW_NOINTERACT cleared
source "$(dirname "$0")/lib.sh"
hook on-add_pty <<HOOK
#!/bin/sh
IFS= read -r t
if [ -n "\$TW_NOINTERACT" ]; then
  echo '{"type": "tw_needs_pty", "cmd": ""}' >&2; exit 1
fi
echo "\$TW_CLIENT" > "$T/client.log"
echo "\$t"
HOOK
t add alpha
start_vit vt
prompt a "needs terminal"
check "asked" wait_for "A hook needs a terminal"
keys y
check "ran in the terminal" wait_for "Press return"
keys Enter; settle
check "added" test "$(field 'description.has:terminal' '.[0].status')" = pending
check "TW_CLIENT kept" grep -qx vit "$T/client.log"
