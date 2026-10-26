# Bug 3: D on an annotation removes it, and never runs its text as shell
source "$(dirname "$0")/lib.sh"
t add alpha
t 1 annotate 'x $(touch PWNED) y'
start_vit vt
select_text PWNED
keys D; sleep 0.2; keys y; settle
check "nothing ran" test ! -e "$WORK/PWNED"
check "annotation removed" test "$(field 'description:alpha' '.[0].annotations // [] | length')" = 0
