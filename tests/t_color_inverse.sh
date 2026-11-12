# an inverse colour (\e[4;7m labels, \e[7m tagged) is an attribute, not a colour: vit drew
# with fg 7-30 = -23 and died ("non-creatable array value, subscript -23"; tw's reports do this)
source "$(dirname "$0")/lib.sh"
cat >> "$TASKRC" <<RC
color=on
color.label=underline inverse
color.tagged=inverse
RC
t add alpha +x; t add beta
start_vit vt
check "alpha listed" wait_for alpha
check "beta listed" wait_for beta
keys Q
check "exit status 0" wait_for "VIT-EXIT:0"
