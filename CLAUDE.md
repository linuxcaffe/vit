# vit — CLAUDE.md

VIT 1.x, Steve Rader's Perl/Curses full-screen client for Taskwarrior, being adopted into the tw fleet
(`~/dev/awesome-taskwarrior`). The plan, the review and the decisions live in the nb notebook:
**`tw:docs/vit-plan.md`** (`~/.nb/tw/docs/`). Read it before changing behaviour.

- **Taskwarrior 2.6.2 is the spec.** No 3.x work, ever. vit reads `task`'s own report output, which is
  stable because 2.6.2 is frozen.
- **Keep the design** (a curses screen over `task`'s reports, vim keys, `.vitrc` maps). Fix how it calls
  `task`, not what it is.
- Branch `1.3` is the line (the fork's default). `origin/2.x` (upstream's Python rewrite) is ignored for good.
- GitHub only (`linuxcaffe/vit`), like the other fleet apps.

## Layout

| File | Role |
|---|---|
| `vit.pl` | Globals, `use` lines, `require`s, main sequence |
| `getch.pl` | The key loop: one `if` per key in `CASE:` (each ends with `last CASE`) |
| `cmds.pl` | Key actions: add, annotate, done, delete/denotate, modify, priority, project, tags, wait, `:!` |
| `exec.pl` | Every `task` call, no shell: `task_open` (argv, own session so no `/dev/tty`, `rc.hooks=off` on reads, the TW_* contract on writes, 15 s `timeout`), `task_read`, `task_check`, `task_exec` (a captured write: `tw_needs_pty` → the terminal, then the spool; a hook's `reason` / `.reason` in the question), `shell_exec` (curses suspended, real terminal; argv, or a string for `/bin/sh` for `:!` maps), `split_args`/`quote_args` |
| `read.pl` | `read_report`: runs `stat`, `projects`, `tags` and the report; builds `@report2taskid` |
| `env.pl` | Startup: `task show` for colors, reports, `default.command` |
| `color.pl`, `draw.pl`, `screen.pl`, `curses.pl` | ANSI parsing into curses color pairs, drawing |
| `prompt.pl`, `search.pl`, `cmdline.pl` | Prompts (tab completion, history), `/` `?` search, `:` commands |
| `vitrc.pl` | `~/.task/config/vitrc`, else `~/.vitrc` (one, never both; not taskrc syntax): `map KEY=ACTION`, `set NAME=yes\|no` |
| `commands` | The `:help` text; the build appends it after `__DATA__` (`show_help` in `cmdline.pl`) |

`build.sh` joins them into one script (`build/vit`): `vit.pl` without its `require` lines, then each part
without its trailing `return 1;`. So **every part shares one namespace**, and `^require`/`^return` at the
start of a line are build syntax: don't start a real line of code with either. The parts come
*after* `vit.pl`'s main sequence, which ends in `exit`, so **a part's top-level statements never run**:
parts define subs only, and every global with a value is set in `vit.pl`. `%VERSION%` and `%BUILD%`
in `vit.pl` are filled in by the build; the help text goes after `__DATA__`, so the built `vit` is the
one file to install (plus the man pages).
The installed copy until the fleet installer lands is `/usr/local/bin/vit` (root-owned, built 2025-01-17).

## Testing

```bash
tests/run.sh               # build, then every tests/t_*.sh (~15 s)
tests/run.sh stale_id      # one test
```

- Each test drives the built vit in a **detached tmux session** with a throwaway `HOME`, `TASKRC` and
  database (`tests/lib.sh`), then checks `task export` with `jq`, or the screen. Never `~/.task`, never the
  real `~/.vitrc`; `lib.sh` refuses a data dir under `~/.task`.
- **Found a bug? Write the failing test first**, add it to `tests/xfail.txt`, then fix: the fix turns it
  into an XPASS, which fails the run until its line is removed.
- Helpers: `t` (quiet `task`), `start_vit REPORT`, `select_text TEXT` (vit's `/` search),
  `prompt KEY TEXT`, `keys`, `settle` (until the screen stops changing), `field FILTER JQ`, `check MSG CMD…`.
  Use report `vt` (id, project, description, sorted by description) so lines have a known order.
- vit runs with a **closed PATH** (`$T/bin`, task's folder, `/usr/local/bin`, `/usr/bin`, `/bin`), so a
  command installed for the user (`gittw` in `~/.task/scripts`) can never touch real data from a test;
  `fake_cmd NAME` puts a fake first on it.
- The pre-commit hook (`.tools/pre-commit`) runs the suite. Install once per clone:
  `ln -sf ../../.tools/pre-commit .git/hooks/pre-commit`.
- **Against the real setup, safely** (what the throwaway database can't show: your reports, colours,
  contexts, hooks, `tw` and its wrappers): copy it into a scratch HOME and cut it off from the remotes.
  ```bash
  S=<scratchpad>/real; mkdir -p $S/home && cp -a ~/.task $S/home/.task && cp ~/.taskrc $S/home/
  for r in $(git -C $S/home/.task remote); do git -C $S/home/.task remote remove $r; done
  E="env -u TASKRC -u TW_TASK_DIR -u TW_CLIENT -u TW_NOINTERACT HOME=$S/home PATH=<bin>:$S/home/.task/scripts:/usr/local/bin:/usr/bin:/bin"
  tmux -L <name> new-session -d -x 150 -y 40 -c $S "$E vit next; sleep 60"   # then send-keys / capture-pane
  ```
  `<bin>` holds what you're testing first: `vit` → `build/vit`, and the dev `tw` as a script running
  `python3 ~/dev/awesome-taskwarrior/tw "$@"` (the repo's `tw` isn't executable; a symlink falls through
  to the installed one). Hooks run on writes in the copy (that's the point); its git has no remotes, so
  gittw can't push. Delete the copy afterwards. (tw-web's CLAUDE.md lists a planned `taskutil fixture`
  for this.)
- Interactive debugging: `build/vit -audit` logs every `task` call to `$XDG_RUNTIME_DIR/vit/vit_audit.log`
  (`~/.cache/vit/` without it), and says where on exit. The tests set `XDG_RUNTIME_DIR` to their temp dir.

## Rules

1. **No shell for `task`: every call goes through `exec.pl`.** argv lists; free text (annotations,
   denotate patterns) after `--`. What the user types as a command line (`a`, `m`, `f`, `:REPORT FILTER`)
   goes through `split_args` (split like a terminal would, never run by `sh`). `:!` maps and spooled hook
   commands are shell commands on purpose.
2. **Reads:** `task_open({ read => 1 })`: `rc.hooks=off`. **Context:** vit follows the CLI's context, as
   `task` does (no `rc.context` override). `--version` takes no `rc.` overrides at all (`bare`).
3. **Writes:** `task_exec`: `rc.confirmation=no` (vit has asked), `rc.recurrence.confirmation=no` (a
   recurring instance alone), `TW_NOINTERACT=1 TW_CLIENT=vit TW_PREFLIGHT_CMD TW_SPOOL_DIR`; a
   `tw_needs_pty` / `TW_INTERACTIVE_REQUIRED` answer offers the command again in the terminal, where
   `shell_exec` clears the no-terminal variables (`~/dev/awesome-taskwarrior/CONVENTIONS.md`).
   **Writes by UUID** (`selected_uuid`, from `@report2uuid`, mapped at each read with one `_get`):
   IDs shift when tw-web or a gittw pull changes the data. After a re-read the selection follows the
   task (`follow_selection`). Messages may still show the ID; arguments never use it.
4. **User text is never a regex** except in a search (`/`, `?`), where a bad pattern is matched literally.
   `:REPORT` matches report names by `eq`/prefix, `:h TEXT` by `index`, case-insensitive.
5. **tw is harnessed, never duplicated, never required** (plan: "Harnessing tw"). `ui()` is `tw` when
   it's on PATH (asked each time), else `task`: the report (`task_open` `ui`), writes and terminal
   commands use it; bookkeeping reads (`stats`, `projects`, `tags`, `_get`) always use `$task` (a tw call
   costs ~0.2 s). vit keeps no copy of tw's grammar: `@` and `t` hand typed text to `tw`; wrapper keywords
   come from tw's `.tw_wrappers` (`tw_wrappers`). Tests run on a closed PATH without tw; `fake_tw` adds
   one that logs and runs task. `TW_CLIENT=vit` (set for writes and terminal commands) is what keeps tw's
   `tw.ui=vit` mode from opening a vit inside vit.
6. **Fleet fit:** `P` offers `uda.priority.values` as the taskrc defines them (read at start); `s` runs
   `gittw sync` when gittw is on PATH, with `TW_TASK_DIR` from task's `data.location`, else `task sync`.
7. `$SIG{__WARN__}` makes any Perl warning fatal, on purpose. Keep the code warning-free.

## Releasing (fleet)

`vit.meta` + `vit.install` (`# HANDCRAFTED`) live here; `make-awesome.py` copies them into
`~/dev/awesome-taskwarrior` (`registry.d/`, `installers/`). The built **`vit` is committed** at each release
(the `.meta` checksum covers it), with the man pages and `README.md`.

1. Set `VERSION` (no `-dev`), `version=` in `vit.meta`, `VERSION=` in `vit.install`; a `CHANGES` line.
2. `./build.sh vit` (a release build has no date or hash, so it's reproducible); the pre-commit hook
   refuses a staged `vit` that isn't a fresh build.
3. `tests/run.sh` (make-awesome's Testing stage only runs `test-*.py`, not this suite).
4. The user runs `make-awesome.py "vit X.Y.Z: …" --dry-run`, then for real (its meta stage asks questions).
5. Wait for raw GitHub (~5 min), check `registry.d/vit.meta` and `index.json`, then `tw -I vit` / `tw -u vit`
   on yoga only, and sync (fleet: one station).
6. Back to `X.Y.Z+1-dev` in `VERSION`.

## Time log

Log milestones to `~/.nb/claude/accounting/dev_timelog.md` under the account `vit:<topic>` (see the
tw-web CLAUDE.md for the format).
