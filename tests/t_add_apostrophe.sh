# Bug 2: an apostrophe in an added task is text
source "$(dirname "$0")/lib.sh"
t add alpha
start_vit vt
prompt a "don't forget"
check "task added" test "$(field 'description:forget' '.[0].description')" = "don't forget"
