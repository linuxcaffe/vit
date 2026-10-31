# nicedates=on: date columns read Yesterday / Today / Tomorrow 3pm / Thursday / Nov20 / Apr1'27,
# each cell as wide as before, so the columns stay where task put them; other text is left alone
source "$(dirname "$0")/lib.sh"
export LC_ALL=C
day() { date -d "$1" +%F; }
cat >> "$TASKRC" <<RC
nicedates=on
report.nd.columns=id,due,scheduled,due.relative,description
report.nd.labels=ID,Due,Sched,Rel,Description
report.nd.sort=description+
report.nd.filter=status:pending
RC
t add a1 due:$(day yesterday)
t add a2 due:$(day today)
t add a3 due:$(day tomorrow)T15:00
t add a4 due:$(day tomorrow)T15:30
t add a5 due:$(day '+4 days')
t add a6 due:$(day '+20 days')
t add a7 due:$(( $(date +%Y) + 1 ))-04-01
t add a8 "$(day tomorrow) 10:00 in the text"
t add a9 scheduled:$(day today)
start_vit nd
line() { screen | grep -E " $1( |$)"; }   # the task's line, by its description
has() { line "$1" | grep -qF -- "$2"; }
far="$(date -d '+20 days' +%b%-d)"; [ "$(date -d '+20 days' +%Y)" = "$(date +%Y)" ] || far="$far'$(date -d '+20 days' +%y)"
for want in "a1:Yesterday " "a2:Today " "a3:Tomorrow 3pm " "a4:Tomorrow 3:30pm " \
            "a5:$(date -d '+4 days' +%A) " "a6:$far " "a7:Apr1'$(date -d '+1 year' +%y) "; do
  check "${want#*:}for ${want%%:*}" has "${want%%:*}" "${want#*:}"
done
check "scheduled too" has a9 "Today "
check "text left alone" has a8 "$(day tomorrow) 10:00 in the text"
check "no date left in a date column" test "$(screen | grep -cE '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}')" = 1
# the columns stay put: every description starts under the Description label
col="$(screen | grep -m1 'Description' | awk '{ print index($0, "Description") }')"
for n in 1 2 3 4 5 6 7 8 9; do
  check "a$n's description in its column" test "$(line a$n | awk -v d=a$n '{ print index($0 " ", " " d " ") + 1 }')" = "$col"
done
keys C-n; settle
check "Ctrl-N: off" wait_for "Nice dates off"
check "real dates" has a2 "$(day today)"
check "no Today" test "$(screen | grep -c 'Today')" = 0
keys C-n; settle
check "Ctrl-N: on again" wait_for "Nice dates on"
check "Today again" has a2 "Today "
