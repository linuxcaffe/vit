# a click inside a prompt is ignored, not typed; set mouse=no leaves the mouse to the terminal
source "$(dirname "$0")/lib.sh"
t add alpha
start_vit vt
keys a; sleep 0.2; type_text "be"; click 5; right_click 3; wheel up; type_text "ta"; keys Enter; settle
check "typed text only" test "$(field 'description:beta' '.[0].description')" = beta
keys Q; settle
echo "set mouse=no" > "$HOME/.vitrc"
restart_vit vt
check "mouse left alone" test "$(tmux -L "$TMUX_SOCK" display -p '#{mouse_any_flag}')" = 0
