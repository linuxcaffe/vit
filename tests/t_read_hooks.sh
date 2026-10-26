# Bug 5: re-reading the report runs no hooks
source "$(dirname "$0")/lib.sh"
mkdir -p "$HOME/hooks"
printf '#!/bin/sh\necho run >> %s/hooks.log\n' "$T" > "$HOME/hooks/on-launch_count"
chmod +x "$HOME/hooks/on-launch_count"
sed -i 's/^hooks=off/hooks=on/' "$TASKRC"
echo "hooks.location=$HOME/hooks" >> "$TASKRC"
t add alpha
start_vit vt
before=$(wc -l < "$T/hooks.log")
keys C-l; settle
after=$(wc -l < "$T/hooks.log")
check "no hooks on a re-read ($before before, $after after)" test "$before" = "$after"
