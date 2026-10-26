# A annotates the selected task
source "$(dirname "$0")/lib.sh"
t add alpha; t add beta
start_vit vt
select_text beta
prompt A "a plain note"
check "annotated" test "$(field 'description:beta' '.[0].annotations[0].description')" = "a plain note"
check "alpha untouched" test "$(field 'description:alpha' '.[0].annotations // "none"')" = none
