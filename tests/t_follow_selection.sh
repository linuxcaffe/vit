# After a re-read, the selection stays on the same task, not the same line
source "$(dirname "$0")/lib.sh"
t add beta; t add gamma; t add zulu
start_vit vt
select_text gamma                            # line 2
t add aardvark                               # sorts first: gamma is line 3 now
keys C-l; settle
keys d; sleep 0.2; keys y; settle
check "gamma completed" test "$(field 'description:gamma' '.[0].status')" = completed
check "beta untouched" test "$(field 'description:beta' '.[0].status')" = pending
