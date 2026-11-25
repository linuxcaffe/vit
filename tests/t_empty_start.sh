# A report with no matches at startup opens, empty, and says so: it isn't "Fatal error:
# default.command ... must print an "ID" column" (djp 2026-11-24: `tw +domain list`, every match
# waiting or a template). A real report without an ID column still stops vit.
source "$(dirname "$0")/lib.sh"
t add -- plain visible task
t add hidden later task +later wait:tomorrow
start_vit +later list
check "vit stopped: $(screen | tail -3)" sh -c "! tmux -L '$TMUX_SOCK' capture-pane -p | grep -q 'VIT-EXIT'"
check "no 'no matches' note: $(screen | head -5)" sh -c "tmux -L '$TMUX_SOCK' capture-pane -p | grep -qi 'no matches'"
check "the header names another report: $(screen | head -1)" sh -c "tmux -L '$TMUX_SOCK' capture-pane -p | head -1 | grep -q 'task +later list'"
# Still usable: another report shows its tasks
prompt : "list"
wait_for "plain visible task" || fail "':list' after an empty start shows nothing: $(screen)"
keys q; sleep 0.2; keys y
wait_for "VIT-EXIT:0" || fail "q didn't quit cleanly: $(screen | tail -3)"
