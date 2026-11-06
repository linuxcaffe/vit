# the sort column's label is drawn in color.label.sort, as task itself does
source "$(dirname "$0")/lib.sh"
cat >> "$TASKRC" <<'RC'
color=on
color.label=white on blue
color.label.sort=black on green
RC
t add alpha project:home
start_vit vt
line=$(tmux -L "$TMUX_SOCK" capture-pane -p -e | sed -n 3p)
# the background in force just before a label
bg() { printf '%s' "$line" | sed -E "s/$1.*//" | grep -oE $'\x1b\\[(4[0-7]|48;5;[0-9]+)m' | tail -1 | tr -d '\033'; }
check "Proj on blue: $(bg Proj)" test "$(bg Proj)" = "[44m"
check "Description on green: $(bg Description)" test "$(bg Description)" = "[42m"
