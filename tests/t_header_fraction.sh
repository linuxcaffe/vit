# the header: "N/TOTAL tasks", TOTAL being the report with no context and no typed filter
source "$(dirname "$0")/lib.sh"
t add alpha project:home; t add beta project:home; t add gamma project:work; t add old project:home; t description:old done
echo 'context.h=project:home' >> "$TASKRC"
start_vit vt
check "whole report" bash -c "tmux -L '$TMUX_SOCK' capture-pane -p | head -1 | grep -qE ' 3 tasks\$'"
keys :; sleep 0.2; type_text "vt project:work"; keys Enter; settle
check "typed filter" bash -c "tmux -L '$TMUX_SOCK' capture-pane -p | head -1 | grep -qE ' 1/3 tasks\$'"
t context h
keys :; sleep 0.2; type_text "vt"; keys Enter; settle
check "context" bash -c "tmux -L '$TMUX_SOCK' capture-pane -p | head -1 | grep -qE ' 2/3 tasks\$'"
keys :; sleep 0.2; type_text "completed"; keys Enter; settle
check "completed counts its own" bash -c "tmux -L '$TMUX_SOCK' capture-pane -p | head -1 | grep -qE ' 1 task\$'"
