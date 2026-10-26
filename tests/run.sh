#!/usr/bin/env bash
# tests/run.sh — build vit, then run the tmux tests (tests/t_*.sh)
#
#   tests/run.sh [name…]     e.g. tests/run.sh add_plain stale_id
#
# A test is a bash script that sources lib.sh and exits 0 to pass. A test that
# reproduces a known bug is listed in tests/xfail.txt: it must fail (XFAIL) until
# the bug is fixed; then it passes (XPASS), which fails the run until its line
# is removed.
set -uo pipefail

cd "$(dirname "$0")/.."
for tool in tmux task jq perl; do
  command -v "$tool" >/dev/null || { echo "missing: $tool" >&2; exit 2; }
done
./build.sh >/dev/null || exit 1

xfail=" $(grep -v '^\s*\(#\|$\)' tests/xfail.txt 2>/dev/null | awk '{print $1}' | tr '\n' ' ') "

if (( $# )); then
  files=(); for n in "$@"; do files+=("tests/t_${n}.sh"); done
else
  files=(tests/t_*.sh)
fi

pass=0 bad=0 xf=0
for f in "${files[@]}"; do
  name="$(basename "$f" .sh)"; name="${name#t_}"
  out="$(timeout 90 bash "$f" 2>&1)"; rc=$?
  if [[ "$xfail" == *" $name "* ]]; then
    if (( rc == 0 )); then echo "XPASS $name  (fixed? remove it from tests/xfail.txt)"; ((bad++))
    else echo "xfail $name"; ((xf++)); fi
  elif (( rc == 0 )); then echo "ok    $name"; ((pass++))
  else echo "FAIL  $name"; sed 's/^/      /' <<<"$out"; ((bad++)); fi
done

echo "--- $pass passed, $xf expected failures, $bad failed"
(( bad == 0 ))
