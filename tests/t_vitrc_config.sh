# ~/.task/config/vitrc is read first; ~/.vitrc only when it's absent (t_uuid_map covers that)
source "$(dirname "$0")/lib.sh"
mkdir -p "$HOME/.task/config"
echo "map X=:!w echo fleet > $T/which.txt<Return>" > "$HOME/.task/config/vitrc"
echo "map X=:!w echo home > $T/which.txt<Return>" > "$HOME/.vitrc"
t add alpha
start_vit vt
keys X
check "ran" wait_for "Press return"
keys Enter; settle
check "vitrc wins" test "$(cat "$T/which.txt")" = fleet
