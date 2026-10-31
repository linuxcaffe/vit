# nicedates is off without the taskrc's nicedates=on; the vitrc's "set nicedates=no" wins over it;
# nice.format.* and nice.conceal-times shape the labels
source "$(dirname "$0")/lib.sh"
export LC_ALL=C
day() { date -d "$1" +%F; }
t add a1 due:$(day tomorrow)T15:00
t add a2 due:$(day tomorrow)T15:30
t add a3 due:$(day '+4 days')
has() { screen | grep " $1\$" | grep -qF -- "$2"; }   # vt: the description ends the line
restart() { restart_vit vt; }
fmt() { echo "report.vt.columns=id,due,description" >> "$TASKRC"; echo "report.vt.labels=ID,Due,Description" >> "$TASKRC"; }
fmt
start_vit vt
check "off by default" test "$(screen | grep -c 'Tomorrow')" = 0
echo "nicedates=on" >> "$TASKRC"
echo "set nicedates=no" > "$HOME/.vitrc"
restart
check "the vitrc turns it off" test "$(screen | grep -c 'Tomorrow')" = 0
rm "$HOME/.vitrc"
cat >> "$TASKRC" <<RC
nice.format.time=h:N
nice.format.week=a
nice.conceal-times=00:00:00,15:00:00
RC
restart
check "time format" has a2 "Tomorrow 15:30"
check "concealed time" has a1 "Tomorrow  "
check "week format" has a3 " $(date -d '+4 days' +%a) "
