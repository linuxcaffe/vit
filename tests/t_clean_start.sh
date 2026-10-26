# vit prints nothing but its version for --version: no compile-time warnings on stderr
source "$(dirname "$0")/lib.sh"
out="$("$VIT" --version 2>&1)"
check "only the version (got: $out)" test "$out" = "$(cut -d' ' -f1 < "$(dirname "$0")/../VERSION")"
