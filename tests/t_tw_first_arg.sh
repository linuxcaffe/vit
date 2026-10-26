# tw reads its shortcuts (@_, @: work) only as the first argument: in the report vit sends to tw,
# the user's words come first and vit's rc. overrides after; :@_ vt is a report command; f keeps
# the filter (and its @_) in front
source "$(dirname "$0")/lib.sh"
fake_tw
t add alpha +x; t add beta
start_vit vt
check "report: user's words first" grep -q '^vt rc\.' "$T/tw.log"
prompt : "@_ vt"
check ":@_ vt accepted" bash -c "! tmux -L $TMUX_SOCK capture-pane -p | grep -q 'command not found'"
check "@_ first" grep -q '^@_ vt rc\.' "$T/tw.log"
keys f; check "filter offered" wait_for "Filter: @_"
keys C-u; type_text "@_ +x"; keys Enter; settle
check "@_ still first" grep -q '^@_ +x vt rc\.' "$T/tw.log"
