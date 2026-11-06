# when the id,uuid listing doesn't line up with the report, a no-ID line gets no UUID: refused, never guessed
source "$(dirname "$0")/lib.sh"
fake_cmd tw <<'SH'
#!/bin/sh
case "$*" in
  *columns=id,uuid*) task "$@" | sed 1d ;;
  *) exec task "$@" ;;
esac
SH
t add alpha; t add beta; t description:alpha done; t description:beta done
start_vit completed
select_text beta
keys m
check "refused" wait_for "No task on this line"
check "nothing changed" test "$(field 'description:beta' '.[0].project // ""')" = ""
