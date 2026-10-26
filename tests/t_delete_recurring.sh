# D on a recurring instance deletes that instance only (plan decision F)
source "$(dirname "$0")/lib.sh"
echo 'recurrence.limit=3' >> "$TASKRC"
t add zz rec due:today recur:daily
t vt
before=$(task rc.verbose=nothing status:pending count 2>/dev/null)
start_vit vt
select_text "zz rec"
keys D; sleep 0.2; keys y; settle
check "one deleted ($before pending before)" test "$(task rc.verbose=nothing status:pending count 2>/dev/null)" = $(( before - 1 ))
