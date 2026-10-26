#!/usr/bin/env bash
# build.sh — join vit.pl and its parts into the single vit script
#
#   ./build.sh [OUT]        default OUT: build/vit
#
# The help text (commands) goes in after __DATA__, so vit never looks for a file.
#
# Replaces configure + Makefile.in (the same join, without autoconf).
set -euo pipefail

cd "$(dirname "$0")"
OUT="${1:-build/vit}"
PARTS="args.pl cmdline.pl cmds.pl color.pl curses.pl draw.pl env.pl exec.pl
  getch.pl misc.pl prompt.pl read.pl search.pl screen.pl vitrc.pl"

VERSION="$(cat VERSION)"
if git rev-parse --short HEAD >/dev/null 2>&1; then
  VERSION="$VERSION ($(git rev-parse --short HEAD))"
fi
BUILD="$(cat VERSION) built after $(date -u -r CHANGES)"

mkdir -p "$(dirname "$OUT")"
tmp="$OUT.tmp.$$"
trap 'rm -f "$tmp"' EXIT

{
  grep -v '^require' vit.pl \
    | sed -e "s|%BUILD%|$BUILD|" -e "s|%VERSION%|$VERSION|"
  for f in $PARTS; do
    echo "########################################################"
    echo "## $f..."
    grep -v '^return' "$f"
  done
  echo "__DATA__"
  cat commands
} > "$tmp"

perl -c "$tmp" 2>/dev/null || { perl -c "$tmp"; exit 1; }
chmod 755 "$tmp"
mv "$tmp" "$OUT"
echo "built $OUT ($VERSION)"
