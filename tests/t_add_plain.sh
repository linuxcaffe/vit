# a adds a task; attributes on the line are parsed, as at a terminal
source "$(dirname "$0")/lib.sh"
t add alpha
start_vit vt
prompt a "buy milk project:home +shop"
check "task added" test "$(field 'description:buy' '.[0].description')" = "buy milk"
check "project parsed" test "$(field 'description:buy' '.[0].project')" = home
check "tag parsed" test "$(field 'description:buy' '.[0].tags[0]')" = shop
