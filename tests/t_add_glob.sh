# Bug 2: * in an added task is text, not a glob over vit's cwd
source "$(dirname "$0")/lib.sh"
touch "$WORK/SOMEFILE"
t add alpha
start_vit vt
prompt a "pay bills * now"
check "no file names in it" test "$(field 'description.has:bills' '.[0].description')" = "pay bills * now"
