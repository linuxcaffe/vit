# tests/lib.sh — helpers for vit's tmux tests (sourced by run.sh, one test per process)
#
# Each test gets a throwaway HOME, TASKRC and task database under a fresh temp dir,
# and drives the built vit in a detached tmux session on its own socket.
# Nothing here may touch ~/.task or the real ~/.vitrc.

REAL_HOME="$HOME"
T="$(mktemp -d "${TMPDIR:-/tmp}/vit-test.XXXXXX")"
export HOME="$T/home"
export TASKRC="$HOME/.taskrc"
DATA="$T/data"
WORK="$T/work"            # vit's cwd
TMUX_SOCK="vit-test-$$"
VIT="${VIT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/build/vit}"

BIN="$T/bin"              # first on vit's PATH: fake commands (fake_cmd)
mkdir -p "$HOME" "$DATA" "$WORK" "$T/run" "$BIN"
unset TASKDATA TW_NOINTERACT TW_CLIENT TW_WEB TW_SPOOL_DIR

# Refuse anything that could reach the real task data.
case "$(readlink -f "$DATA")" in
  "$(readlink -f "$REAL_HOME")/.task"*) echo "refusing: $DATA is under ~/.task" >&2; exit 2 ;;
esac

cat > "$TASKRC" <<EOF
data.location=$DATA
hooks=off
confirmation=no
news.version=2.6.2
# vt: a fixed order, so a test knows which line is where
report.vt.columns=id,project,description
report.vt.labels=ID,Proj,Description
report.vt.sort=description+
report.vt.filter=status:pending
EOF

teardown() {
  tmux -L "$TMUX_SOCK" kill-server 2>/dev/null || true
  # kill-server leaves the socket file behind: one per test run otherwise
  rm -f "${TMUX_TMPDIR:-/tmp}/tmux-$(id -u)/$TMUX_SOCK"
  rm -rf "$T"
}
trap teardown EXIT

# vit's PATH: the system's only, so nothing installed for the user (gittw in ~/.task/scripts,
# say) can reach real data; tests add fakes with fake_cmd
TASK_DIR_OF_BIN="$(dirname "$(command -v task)")"
VIT_PATH="$BIN:$TASK_DIR_OF_BIN:/usr/local/bin:/usr/bin:/bin"

# fake_cmd NAME — install stdin as an executable NAME on vit's PATH
fake_cmd() { cat > "$BIN/$1"; chmod +x "$BIN/$1"; }

# t — run task against the throwaway database, quietly
t() { task rc.verbose=nothing "$@" >/dev/null 2>&1; }

# start_vit ARGS… — start vit in tmux; waits until the report header shows (the first
# argument that isn't a -switch is the report)
start_vit() {
  tmux -L "$TMUX_SOCK" new-session -d -x 120 -y 30 -c "$WORK" \
    "env HOME='$HOME' TASKRC='$TASKRC' XDG_RUNTIME_DIR='$T/run' PATH='$VIT_PATH' '$VIT' $*; echo VIT-EXIT:\$?; sleep 600"
  local report=next a
  for a in "$@"; do [[ "$a" == -* ]] || { report="$a"; break; }; done
  wait_for "task $report" || fail "vit didn't start"
  settle
}

screen() { tmux -L "$TMUX_SOCK" capture-pane -p; }

# wait_for TEXT [SECONDS] — until TEXT (fixed string) is on the screen
wait_for() {
  local text="$1" n=$(( ${2:-5} * 10 ))
  while (( n-- > 0 )); do
    screen | grep -qF -- "$text" && return 0
    sleep 0.1
  done
  return 1
}

# settle — until the screen stops changing (vit has re-read and redrawn)
settle() {
  local prev cur n=50
  prev="$(screen)"
  while (( n-- > 0 )); do
    sleep 0.2
    cur="$(screen)"
    [[ "$cur" == "$prev" ]] && return 0
    prev="$cur"
  done
}

keys() { tmux -L "$TMUX_SOCK" send-keys "$@"; }
type_text() { tmux -L "$TMUX_SOCK" send-keys -l -- "$1"; }

# prompt KEY TEXT — open a vit prompt with KEY, type TEXT, press Enter
prompt() { keys "$1"; sleep 0.2; type_text "$2"; keys Enter; settle; }

# select_text TEXT — move the selection to the line matching TEXT (vit's / search)
select_text() { keys /; sleep 0.2; type_text "$1"; keys Enter; settle; }

vit_exited() { screen | grep -q '^VIT-EXIT:'; }

# field FILTER JQ — a jq expression over task export
field() { task rc.verbose=nothing $1 export 2>/dev/null | jq -r "$2"; }

fail() { echo "FAIL: $*" >&2; echo "--- screen:" >&2; screen >&2 2>/dev/null; exit 1; }
check() { local msg="$1"; shift; "$@" || fail "$msg"; }

# hook NAME — install stdin as an executable hook in the throwaway database and turn hooks on
# (on-add/on-modify hooks get the task JSON on stdin and must echo it back)
hook() {
  mkdir -p "$HOME/hooks"
  cat > "$HOME/hooks/$1"; chmod +x "$HOME/hooks/$1"
  sed -i 's/^hooks=off/hooks=on/' "$TASKRC"
  grep -q '^hooks.location=' "$TASKRC" || echo "hooks.location=$HOME/hooks" >> "$TASKRC"
}

# fake_tw — a tw on vit's PATH that logs each call (one line, "$*") to $T/tw.log and runs task;
# like tw, a first argument @_ means no context (rc.context=none)
fake_tw() {
  fake_cmd tw <<FAKE
#!/bin/sh
printf '%s\n' "\$*" >> "$T/tw.log"
if [ "\$1" = "@_" ]; then shift; exec task rc.context=none "\$@"; fi
exec task "\$@"
FAKE
  : > "$T/tw.log"
}
