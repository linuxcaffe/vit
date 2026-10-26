# m modifies in the terminal (quoted words stay one); :s/old/new/ edits the description
source "$(dirname "$0")/lib.sh"
t add alpha; t add beta
start_vit vt
select_text beta
prompt m "+tagged project:'two words'"
check "ran in the terminal" wait_for "Press return"
keys Enter; settle
check "tag" test "$(field 'description:beta' '.[0].tags[0]')" = tagged
check "quoted project" test "$(field 'description:beta' '.[0].project')" = "two words"
select_text beta
prompt : "s/beta/gamma/"
check "ran in the terminal" wait_for "Press return"
keys Enter; settle
check "description edited" test "$(field 'description.has:gamma' '.[0].project')" = "two words"
