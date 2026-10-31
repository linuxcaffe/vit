# A spooled command with a <unique>.reason: vit asks with the reason, shows the command in the
# terminal before it runs, and removes both files
source "$(dirname "$0")/lib.sh"
hook on-add_spool <<HOOK
#!/bin/sh
IFS= read -r t
if [ -n "\$TW_SPOOL_DIR" ]; then
  echo "\$TW_SPOOL_DIR" > "$T/spool-dir"
  echo "touch '$T/spooled-ran'" > "\$TW_SPOOL_DIR/one.cmd"
  echo "myhook: write a note for this task" > "\$TW_SPOOL_DIR/one.reason"
fi
echo "\$t"
HOOK
t add alpha
start_vit vt
prompt a "beta"
check "asked with the reason" wait_for "myhook: write a note for this task"
keys y
check "the command shown" wait_for "touch '$T/spooled-ran'"
check "ran" wait_for "Press return"
keys Enter; settle
check "the command ran" test -e "$T/spooled-ran"
check "the spool emptied" test -z "$(ls -A "$(cat "$T/spool-dir")")"
