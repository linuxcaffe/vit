# t prefills the command prompt with tw when tw is installed, else task
source "$(dirname "$0")/lib.sh"
t add alpha
start_vit vt
keys t; check "task without tw" wait_for ":!rw task"
keys Escape; settle
fake_tw
keys t; check "tw with tw" wait_for ":!rw tw"
keys Escape
