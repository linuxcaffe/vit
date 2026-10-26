# Bug 2: parentheses in an added task are text, not shell syntax
source "$(dirname "$0")/lib.sh"
t add alpha
start_vit vt
prompt a "call mom (sunday)"
check "task added verbatim" test "$(field 'description:call' '.[0].description')" = "call mom (sunday)"
