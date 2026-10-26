# A : word in tw's wrapper list runs tw <uuid> <word> on the selected task; reports win a clash
source "$(dirname "$0")/lib.sh"
fake_tw
mkdir -p "$HOME/.task/config"
printf 'ann|annn|Annotations|command\nvt|x|clash|command\ntheme-switch|t.py|x|pre-exec\n' > "$HOME/.task/config/.tw_wrappers"
t add alpha; t add beta
start_vit vt
select_text beta
prompt : "ann -l"
check "ran" wait_for "Press return"; keys Enter; settle
u=$(task rc.verbose=nothing _get 2.uuid 2>/dev/null)
check "tw <uuid> ann -l" grep -qx "$u ann -l" "$T/tw.log"
prompt : "vt"
check "a report name stays a report" bash -c "! grep -q ' vt\$' <(grep -v '^rc' '$T/tw.log')"
prompt : "theme-switch"
check "pre-exec wrappers aren't commands" wait_for "command not found"
