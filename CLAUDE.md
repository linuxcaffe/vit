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
| `exec.pl` | `task_exec` (output captured, through `sh` today) and `shell_exec` (curses suspended, real terminal) |
| `read.pl` | `read_report`: runs `stat`, `projects`, `tags` and the report; builds `@report2taskid` |
| `env.pl` | Startup: `task show` for colors, reports, `default.command` |
| `color.pl`, `draw.pl`, `screen.pl`, `curses.pl` | ANSI parsing into curses color pairs, drawing |
| `prompt.pl`, `search.pl`, `cmdline.pl` | Prompts (tab completion, history), `/` `?` search, `:` commands |
| `vitrc.pl` | `~/.vitrc`: `map KEY=ACTION`, `set NAME=yes\|no` |
| `commands` | The `:help` text |

`build.sh` joins them into one script (`build/vit`): `vit.pl` without its `require` lines, then each part
without its trailing `return 1;`. So **every part shares one namespace**, and `^require`/`^return` at the
start of a line are build syntax: don't start a real line of code with either. `%prefix%`, `%TASK%`,
`%CLEAR%` in `vit.pl` are placeholders (`PREFIX` env sets the first; the others fall back in `vit.pl`).
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
- The pre-commit hook (`.tools/pre-commit`) runs the suite. Install once per clone:
  `ln -sf ../../.tools/pre-commit .git/hooks/pre-commit`.
- Interactive debugging: `build/vit -audit` logs every `task` call to `./vit_audit.log`.

## Rules (from the plan; most are not true of the code yet)

1. **No shell for `task`.** argv lists; free text (annotations, denotate patterns) after `--`. What the
   user types as a command line (`a`, `m`, `f`, `:REPORT FILTER`) is split like a terminal would, but never
   run by `sh`. `:!` maps are shell commands on purpose.
2. **Reads:** `rc.hooks=off`. **Context:** vit follows the CLI's context, as `task` does.
3. **Writes:** by UUID, not ID (IDs shift when tw-web or a gittw pull changes the data);
   `rc.confirmation=no` once vit has asked; `TW_NOINTERACT=1 TW_CLIENT=vit`, and a `tw_needs_pty` /
   `TW_INTERACTIVE_REQUIRED` answer re-runs the command in the terminal
   (`~/dev/awesome-taskwarrior/CONVENTIONS.md`).
4. **User text is never a regex** unless it's a search (`/`, `?`), and then a bad one is an error message.
5. `$SIG{__WARN__}` makes any Perl warning fatal, on purpose. Keep the code warning-free.

## Time log

Log milestones to `~/.nb/claude/accounting/dev_timelog.md` under the account `vit:<topic>` (see the
tw-web CLAUDE.md for the format).
