# in `all`, a completed task's line (ID -) right under a pending one is not that pending task; and
# coloured (color.alternate), that line isn't taken for a separator and dropped
source "$(dirname "$0")/lib.sh"
cat > "$HOME/.vitrc" <<'RC'
map +=:!r task %TASKUUID start<Return>
RC
echo 'color.alternate=on color8' >> "$TASKRC"
t add beta; t description:beta done; t add alpha
start_vit all
select_text beta
keys +; settle
check "the pending task above isn't started" test "$(field 'description:alpha' '.[0].start // ""')" = ""
keys d; sleep 0.2; settle
check "nor done" test "$(field 'description:alpha' '.[0].status')" = pending
check "the line was beta's" bash -c "tmux -L '$TMUX_SOCK' capture-pane -p | grep -q beta"
