# vit

A full-screen terminal interface for Taskwarrior 2.6.x with Vim key bindings: an uncluttered view of any
report, no mouse, and a keystroke for each common change.

```
tw -I vit        # install (awesome-taskwarrior)
vit              # your default report
vit ls +home     # any report, any filter
```

This is VIT 1.x, Steve Rader's Perl/Curses client, maintained as part of the
[awesome-taskwarrior](https://github.com/linuxcaffe/awesome-taskwarrior) fleet. It targets
**Taskwarrior 2.6.2**. (Upstream's Python rewrite, VIT 2.x, is a separate project.)

## How it works

Every screen is Taskwarrior's own report output, read with its colors and redrawn in curses. Any report,
any columns, your taskrc's colors: nothing to configure twice.

- **Moving:** `j` `k` `G` `gg` `H` `M` `L`, `^f` `^b`, `:N` (task N), `/` `?` `n` `N` (search)
- **Reports:** `:REPORT FILTER` (tab completes report names), `f` to filter the current one, `:summary`
  and Enter on a project
- **Changing the selected task:** `a` add, `d` done, `b` start/stop, `A` annotate, `D` delete (or denotate
  on an annotation line), `m` modify, `P` priority, `p` project, `T` tags, `w` wait, `e` edit, `u` undo,
  `=` or Enter for its information
- **`s`** syncs: `gittw sync` when gittw is installed, else `task sync`
- **`:h`** shows all the keys; `:h TEXT` the lines containing TEXT

## In the fleet

- **It acts on the task you selected.** vit keeps each line's UUID, so a change made elsewhere (tw-web,
  a sync from another station) that renumbers IDs can't redirect a keystroke to another task. After a
  re-read the selection stays on the same task.
- **No shell between vit and `task`.** What you type for `a`, `m` and `f` is split into words the way a
  terminal would (quotes work), but nothing in it is expanded or run: `call mom (sunday)`,
  `don't forget` and `pay bills * now` are plain text. Annotations go after `--`.
- **Hooks:** reads run with `rc.hooks=off`, so a refresh doesn't start every on-launch and on-exit hook.
  Writes follow the fleet's client contract (`CONVENTIONS.md`): hooks are told there's no terminal
  (`TW_NOINTERACT`, `TW_CLIENT=vit`); one that needs a terminal (`tw_needs_pty`) is offered one, and
  commands a hook spools are offered after the change.
- **Priority:** `P` offers your `uda.priority.values`, one key each.
- **Context:** vit follows Taskwarrior's context, as `task` does.

## Configuration: ~/.vitrc

```
map <F9>=:ready<Return>
map o=:!w taskopen %TASKUUID<Return>
set confirmation=no
```

`map KEY=KEYS` binds a key; `:![rw] COMMAND` runs a shell command (`r` re-reads the report, `w` waits for
Enter). In the command, `%TASKUUID` is the selected task's UUID, `%TASKID` its ID and `%TASKARGS` the
current report. Prefer `%TASKUUID` in a map that changes a task: IDs change when the data changes
elsewhere. `set` takes `confirmation`, `wait` and `burndown` (yes/no). See `man vitrc` and `man vit`
(installed under `~/.task/docs/man`: `man -M ~/.task/docs/man vit`).

`-audit` logs every `task` command vit runs to `$XDG_RUNTIME_DIR/vit/vit_audit.log`.

## Requirements

Perl with the Curses, Try::Tiny and Text::CharWidth modules (Debian/Ubuntu:
`libcurses-perl libtry-tiny-perl libtext-charwidth-perl`), and a terminal with color. Desktop stations
(`platforms=desktop`); Termux untried.

## Development

`./build.sh` joins `vit.pl` and its parts into `build/vit`; `tests/run.sh` drives the built vit in tmux
against a throwaway database. A release commits the built `vit` (`./build.sh vit`). See `CLAUDE.md`.

## History

Steve Rader wrote VIT in 2012–2013; he died in May 2013. Scott Kostyshak maintained it until 2018, with
the Taskwarrior team (see `AUTHORS`). VIT 1.4.0 (2026) brings it into the awesome-taskwarrior fleet:
see `CHANGES`.
