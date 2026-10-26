# With tw installed, what the user sees and does goes through tw (report, writes, terminal
# commands); vit's own bookkeeping (stats, projects, tags, _get) stays on task
source "$(dirname "$0")/lib.sh"
fake_tw
t add alpha; t add beta
start_vit vt
check "report through tw" grep -q '^vt rc\.' "$T/tw.log"
check "bookkeeping not through tw" bash -c "! grep -qE '(^| )(stats|projects|tags|_get)( |$)' '$T/tw.log'"
select_text beta
keys d; sleep 0.2; keys y; settle
check "write through tw" grep -q ' done$' "$T/tw.log"
check "and it worked" test "$(field 'description:beta' '.[0].status')" = completed
keys =; check "info ran" wait_for "Press return"; keys Enter; settle
check "terminal command through tw" grep -q ' information$' "$T/tw.log"
