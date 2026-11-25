# A captured write gives hooks no terminal: a hook that ignores TW_NOINTERACT and opens /dev/tty
# can't, so it can't read the user's keys behind the curses screen (deps-mgmt, annn)
source "$(dirname "$0")/lib.sh"
# Set up before the hook: this add runs from the test script, which has a terminal when the suite
# runs from one (make-awesome, the pre-commit hook), and the hook would find it
t add alpha
hook on-add_tty <<HOOK
#!/bin/sh
IFS= read -r t
if ( exec 3<>/dev/tty ) 2>/dev/null; then touch "$T/got-tty"; fi
echo "\$t"
HOOK
start_vit vt
prompt a "beta"
check "added" test "$(field 'description:beta' '.[0].status')" = pending
check "the hook had no terminal" test ! -e "$T/got-tty"
