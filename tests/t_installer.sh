# vit.install, as tw runs it (files staged beside it): installs into ~/.task, records the
# manifest, leaves other apps' lines and ~/.vitrc alone, and removes exactly what it installed
source "$(dirname "$0")/lib.sh"
top="$(cd "$(dirname "$0")/.." && pwd)"
stage="$T/stage"; mkdir -p "$stage" "$HOME/.task/config"
cp "$top/vit" "$top/vit.1" "$top/vitrc.5" "$top/README.md" "$top/vit.install" "$stage/"
echo 'other|1.0|~/.task/scripts/other||x' > "$HOME/.task/config/.tw_manifest"
echo 'map X=:q<Return>' > "$HOME/.vitrc"
env -u TW_TASK_DIR PATH="$VIT_PATH" bash "$stage/vit.install" install >/dev/null 2>&1
check "installed: same as the committed vit" cmp -s "$top/vit" "$HOME/.task/scripts/vit"
check "executable" test -x "$HOME/.task/scripts/vit"
check "man pages" test -f "$HOME/.task/docs/man/man1/vit.1" -a -f "$HOME/.task/docs/man/man5/vitrc.5"
check "README" test -f "$HOME/.task/docs/vit_README.md"
check "4 manifest lines" test "$(grep -c '^vit|' "$HOME/.task/config/.tw_manifest")" = 4
check "manifest version = vit.meta's" grep -q "^vit|$(sed -n 's/^version=//p' "$top/vit.meta")|" "$HOME/.task/config/.tw_manifest"
env -u TW_TASK_DIR bash "$stage/vit.install" remove >/dev/null 2>&1
check "removed" test ! -e "$HOME/.task/scripts/vit" -a ! -e "$HOME/.task/docs/man"
check "other app kept" grep -qx 'other|1.0|~/.task/scripts/other||x' "$HOME/.task/config/.tw_manifest"
check "no vit lines left" bash -c "! grep -q '^vit|' '$HOME/.task/config/.tw_manifest'"
check ".vitrc untouched" grep -qx 'map X=:q<Return>' "$HOME/.vitrc"
