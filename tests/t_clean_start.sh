# vit prints nothing but its version for --version: no compile-time warnings on stderr
# (a -dev build adds its commit: "1.4.1-dev (abc1234)")
source "$(dirname "$0")/lib.sh"
out="$("$VIT" --version 2>&1)"
check "one line (got: $out)" test "$(printf '%s\n' "$out" | wc -l)" = 1
check "the version (got: $out)" test "${out%% *}" = "$(cat "$(dirname "$0")/../VERSION")"
