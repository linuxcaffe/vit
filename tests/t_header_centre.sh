# the header's first line has "vit vVERSION" in the middle, the second the active filter
source "$(dirname "$0")/lib.sh"
t add alpha +x; t add beta
start_vit vt
v="vit v$(cat "$(dirname "$0")/../VERSION")"
check "version centred on line 1" bash -c "screen() { tmux -L $TMUX_SOCK capture-pane -p; }; screen | sed -n 1p | grep -qF '      $v'"
prompt f "+x"
check "beta filtered out" bash -c "! tmux -L $TMUX_SOCK capture-pane -p | grep -q beta"
check "filter centred on line 2" bash -c "tmux -L $TMUX_SOCK capture-pane -p | sed -n 2p | grep -qE '^ {10,}.*filter: \+x  '"
check "filter not in the command" bash -c "tmux -L $TMUX_SOCK capture-pane -p | sed -n 1p | grep -qE '^ *task vt  '"
