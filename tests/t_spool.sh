# A command a hook spooled is offered after the write, and runs if the user says yes
source "$(dirname "$0")/lib.sh"
hook on-add_spool <<HOOK
#!/bin/sh
IFS= read -r t
[ -n "\$TW_SPOOL_DIR" ] && echo "touch '$T/spooled-ran'" > "\$TW_SPOOL_DIR/one.cmd"
echo "\$t"
HOOK
t add alpha
start_vit vt
prompt a "beta"
check "offered" wait_for "A hook asks to run"
keys y
check "ran" wait_for "Press return"
keys Enter; settle
check "the command ran" test -e "$T/spooled-ran"
check "added" test "$(field 'description:beta' '.[0].status')" = pending
