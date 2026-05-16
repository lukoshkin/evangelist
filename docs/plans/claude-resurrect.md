# Claude session resurrection after oomd kills

> Captured during the session that wired up `evn install systemd`.
> Pick up by saying: *"Continue the claude-resurrect plan from `docs/plans/claude-resurrect.md`"*.

## Problem

When `systemd-oomd` kills a kitty scope (one of `chrome`/`slack`/`spotify`
got too heavy and we got picked anyway, or kitty itself was the runaway),
any Claude Code CLI sessions inside that kitty die with it. We want to
resume them automatically — open a new kitty tab in the original CWD and
run `claude -c "Please, continue — interrupted by SWAP saturation"`.

## Building blocks (already on disk, no extra infra needed)

- **Kill detection** — `journalctl -u systemd-oomd.service -f --output=cat`
  emits structured lines like `Killed /user.slice/.../app-org.kde.kitty-XXXX.scope due to memory used (...)`.
  A user systemd service can tail this stream and trigger a script per
  kill event.
- **Per-project session storage** — Claude stores transcripts at
  `~/.claude/projects/<encoded-cwd>/<session-id>.jsonl`. The encoded dir
  name is mechanically reversible:
      `-home-lukoshkin--config-evangelist` → `/home/lukoshkin/.config/evangelist`
  (single `-` for `/`, `--` for a literal `-` in the path).
- **Re-spawn** — pick one:
  - `kitty @ launch --type=tab --cwd="$CWD" -- claude -c` (requires
    `allow_remote_control yes` in `kitty.conf` — we already ship that).
  - `setsid -f kitty --working-directory "$CWD" -- claude -c "..."` for a
    fresh window.

## Design — two flavours

### A. Notify-only (semi-automatic, recommended for v1)

1. User systemd service `claude-resurrect-watcher.service` tails
   `journalctl -u systemd-oomd.service`.
2. On `Killed ` line, the watcher:
   - Parses the cgroup path, confirms it's an `app-org.kde.kitty-` scope.
   - Walks `~/.claude/projects/*/`, picks JSONL files modified in the
     last ~30 s and whose owning `claude` PID is no longer alive.
   - Sends `notify-send` per candidate with a clickable action that
     spawns the new kitty tab.
3. User clicks → tab opens → `claude -c …` runs.

Pros: zero false positives; user is in the loop.
Cons: one extra click per session.

### B. Auto-resurrect (fully automatic)

Same detection, skip the notification, spawn directly.

Pros: zero clicks.
Cons: potential false positives (user closed kitty intentionally with
unsaved Claude state); auto-spawn loop if memory pressure persists.

## Risks and mitigations

- **Clean-exit ↔ kill ambiguity.** Without a wrapper, we can't tell a
  Ctrl-D close from a kill. Mitigation: **only resurrect when the kill
  event arrives within ~30 s of the JSONL's last write**. This windows
  out clean exits where Claude flushed and the user paused before
  closing the terminal.
- **Cgroup ↔ session mapping is heuristic.** oomd kills a kitty *scope*,
  not a specific claude PID. With multiple Claude sessions across
  multiple kitty windows, we don't directly know which died. Mitigation:
  ship a tiny shim that records `(claude_pid, kitty_pid_via_$PPID, $PWD,
  start_ts)` to `$XDG_RUNTIME_DIR/claude-sessions.tsv` on `claude`
  invocation, unlinks on clean exit. Then "PID gone but row still
  present" = killed candidate, with exact CWD.
- **Resurrect-loop on persistent pressure.** Refuse to resurrect the
  same `(cwd, session-id)` more than once per 5 min. State in
  `$XDG_STATE_HOME/claude-resurrect/recent.tsv`.
- **Auth / TTY prompts.** New kitty tab inherits the user's GUI session,
  so no extra auth. `claude -c` reuses the existing OAuth token; if it
  expires the tab will show the login prompt — harmless but worth
  documenting.

## Open questions to resolve when we pick this up

1. **Notify-only or auto?** Personal preference + risk tolerance. Default
   recommendation: notify-only.
2. **Wrap `claude` or rely on JSONL mtimes?** The wrapper makes the
   cgroup→session mapping deterministic; without it we use heuristics
   and accept some false positives. The wrapper is ~20 lines of bash
   plus an `alias claude=…` (or a function shadow in zsh).
3. **Resume prompt** — current draft is *"Please, continue — interrupted
   by SWAP saturation"*. Could be longer / include the kill timestamp /
   include `oomctl` snapshot. Up to user.
4. **Where in evangelist?** `conf/systemd/claude-resurrect/` next to the
   existing OOM hardening — same `evn install systemd` deploys it,
   uninstall removes it.

## Suggested file layout

```
conf/systemd/claude-resurrect/
├── README.md                       # this file's eventual docs version
├── claude-wrapper.sh               # opt-in wrapper; tracks active sessions
├── claude-resurrect-watcher.sh     # tails journal, fires recoveries
├── claude-resurrect.sh             # the actual recovery (open tab + claude -c)
└── files-user/
    └── systemd/user/
        └── claude-resurrect-watcher.service
```

## Implementation order when we pick this up

1. Decide flavour (notify vs auto) and wrapper-yes/wrapper-no via
   `AskUserQuestion`.
2. Ship `claude-resurrect.sh` (recovery primitive). Test by hand:
   `claude-resurrect.sh /home/lukoshkin/some/dir`.
3. Ship `claude-resurrect-watcher.sh` (journalctl tail + glue).
4. Ship the systemd user service unit that runs the watcher.
5. Wire into `install::systemd_settings`: `cp` the user service,
   `systemctl --user enable --now claude-resurrect-watcher`.
6. Wire into `control::uninstall`: stop + disable the service, remove
   files.
7. Document in `conf/systemd/README.md`.

## Out of scope (do NOT build into v1)

- Recovering non-Claude work (vim sessions, build jobs, etc.) — Claude
  is the specific case where the JSONL gives us a free reconstruction
  hook.
- GUI: a tray icon to manage candidates. Notify-send is enough.
- Cross-host (e.g., recovering Claude on a remote SSH session that died
  from local OOM). Out of scope.
