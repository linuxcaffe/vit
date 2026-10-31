# A tw_needs_pty with a reason: vit's question says it (cut to fit, the question kept)
source "$(dirname "$0")/lib.sh"
hook on-add_pty <<HOOK
#!/bin/sh
IFS= read -r t
if [ -n "\$TW_NOINTERACT" ]; then
  echo '{"type": "tw_needs_pty", "cmd": "", "reason": "myhook: needs \\"you\\" to pick a colour for this one, and this reason goes on and on far past the edge of any screen"}' >&2; exit 1
fi
echo "\$t"
HOOK
t add alpha
start_vit vt
prompt a "needs terminal"
check "the reason shown" wait_for 'myhook: needs "you" to pick'
check "the question kept" wait_for "Run it in the terminal?"
keys y
check "ran in the terminal" wait_for "Press return"
keys Enter; settle
check "added" test "$(field 'description.has:terminal' '.[0].status')" = pending
