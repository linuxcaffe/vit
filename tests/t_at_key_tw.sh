# With tw, @ opens a tw @ prompt: what's typed goes to tw unchanged (cmx and all)
source "$(dirname "$0")/lib.sh"
fake_tw
t add alpha
start_vit vt
keys @; check "tw @ prompt" wait_for ":!r tw @"
type_text "+ home"; keys Enter; settle
check "passed unchanged" grep -qx '@+ home' "$T/tw.log"
