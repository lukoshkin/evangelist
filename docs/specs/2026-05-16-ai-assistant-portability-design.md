# AI Assistant Portability — Design

- **Date:** 2026-05-16 (rev. 2 — incorporates tool research + two install modes)
- **Status:** Design under review; pending implementation plan
- **Scope:** `$EVANGELIST/conf/ai/` — a portable home for the user's
  coding-assistant configuration, with conversion to non-Claude tools.

## Context

The user authors skills, slash commands, and helper scripts for Claude
Code under `~/.claude/`. On work machines tied to customer projects,
Claude Code cannot be used — GitHub Copilot CLI, OpenAI Codex CLI, or
Cursor must be used instead. Today this tooling is trapped in
`~/.claude/` on one machine and in one tool's format.

The `evangelist` dotfiles repo already provisions machines (`conf/<tool>/`
deployed by `evangelist install`). This design extends it to own the
Claude Code configuration and to project a portable subset onto the
other three assistants.

## Goals

- One version-controlled source of truth for skills/commands/helpers.
- Any new machine is fully provisioned for Claude Code by `evangelist
  install`.
- A usable subset reaches Copilot CLI, Codex CLI, and Cursor.
- Editing an artifact never requires manual copying between locations.

## Non-goals

- Porting Claude-Code-only mechanisms (hooks, statusline, permissions)
  as *features* to other tools — those tools lack the concepts.
- A separate tool-neutral authoring format. Claude Code's native format
  is the canonical source; conversion only ever goes outward.
- Designing the user's spec-driven project workflow. The infrastructure
  here will carry such skills/commands once authored, but their content
  is out of scope.

## Decisions

| # | Question | Decision |
|---|----------|----------|
| 1 | Target tools | Claude Code (canonical) + Copilot CLI, Codex CLI, Cursor |
| 2 | Migration engine | Hybrid: deterministic converter + agent prompt |
| 3 | Canonical format | Claude Code native format; convert outward only |
| 4 | Cross-tool scope | commands, skills, helper scripts, `CLAUDE.md`→`AGENTS.md` |
| 5 | Command mapping | Cursor: native command; Codex & Copilot: convert to a skill |
| 6 | CC-only, cross-machine | `statusline.sh` + helpers, `settings.json` |
| 7 | Converted outputs | Generated at install (Approach B); never committed |
| 8 | CC artifact deployment | Symlinked from `~/.claude` into `conf/ai/claude/` |
| 9 | Install modes | User picks Mode 1 (scripted + finalize) or Mode 2 (agent-driven) |

## Tool research (verified May 2026)

Skills are now an **open `SKILL.md` standard** shared across all three
target tools — a Claude skill (`SKILL.md` + `references/` + `scripts/`)
ports almost verbatim. Slash commands are the divergent artifact.

| Claude artifact | → Codex CLI | → Copilot CLI | → Cursor |
|---|---|---|---|
| skill `skills/x/` | copy dir → `~/.agents/skills/x/` | copy dir → `~/.copilot/skills/x/` | copy dir → `.cursor/skills/x/` |
| command `commands/x.md` | wrap as skill → `~/.agents/skills/x/` | wrap as skill → `~/.copilot/skills/x/` | strip frontmatter → `~/.cursor/commands/x.md` |
| `CLAUDE.md` | → `~/.codex/AGENTS.md` | → `~/.copilot/copilot-instructions.md` | → project `AGENTS.md` (no global file) |
| `scripts/*` | shared path; rewrite refs | shared path; rewrite refs | shared path; rewrite refs |
| MCP servers | finalization / delegation prompt | finalization / delegation prompt | finalization / delegation prompt |
| `statusline.sh`, `settings.json` | — (Claude Code only) | — | — |

Rationale for command→skill (decision 5): Codex's custom-prompt format
is officially deprecated in favor of skills, and Copilot CLI has no
user-defined slash commands at all. A slash command is a reusable
prompt, which is what a skill is — so wrapping commands as skills gives
one uniform code path. Cursor keeps native commands (it has them).

## Architecture

### Repo layout

```
$EVANGELIST/conf/ai/
  claude/                      canonical source of truth (version-controlled)
    commands/*.md
    skills/*/SKILL.md (+ references/)
    scripts/*                  check_guard_clauses.py, uv-setup.sh, …
    statusline.sh (+ helpers)
    CLAUDE.md                  global instructions
    settings.json              hooks / permissions / env / enabled-plugins
  convert/
    convert.py                 the converter (entry point)
    adapters/{codex,copilot,cursor}.py
    prompts/
      finalize.md.tmpl         Mode 1 finalization-prompt template
      delegate.md.tmpl         Mode 2 delegation-prompt template
  README.md                    architecture doc + converter-refresh note
```

### Artifact classification

- **Cross-tool** — converted to all three other tools: `commands/`,
  `skills/`, `scripts/`, `CLAUDE.md` → `AGENTS.md`.
- **Agent-handled** — not converted deterministically; covered by the
  finalization prompt (Mode 1) or delegation prompt (Mode 2): MCP
  server configs, and anything an adapter flags as not cleanly
  convertible.
- **Cross-machine only** — carried by evangelist, deployed for Claude
  Code, never converted: `statusline.sh` + helpers, `settings.json`.

### Deployment: symlink the canonical artifacts

`evangelist install ai` symlinks the Claude Code artifacts from
`~/.claude` into the repo, so the live files and the version-controlled
files share an inode — no back-sync step:

```
~/.claude/commands     -> $EVANGELIST/conf/ai/claude/commands
~/.claude/skills       -> $EVANGELIST/conf/ai/claude/skills
~/.claude/scripts      -> $EVANGELIST/conf/ai/claude/scripts
~/.claude/CLAUDE.md    -> $EVANGELIST/conf/ai/claude/CLAUDE.md
~/.claude/statusline.sh-> $EVANGELIST/conf/ai/claude/statusline.sh
~/.claude/settings.json-> $EVANGELIST/conf/ai/claude/settings.json
```

Only these named children are symlinked; the rest of `~/.claude/`
(`plugins/`, `projects/`, …) is untouched. Existing files at those
paths are backed up (evangelist's `utils::back_up_original_configs`)
before the symlink is created. Machine-specific overrides stay in
`~/.claude/settings.local.json`, which is not managed here. Symlinking
happens in **both** install modes — it is Claude Code setup, independent
of the other-tools conversion.

### The converter (`convert.py`)

- **Input:** `$EVANGELIST/conf/ai/claude/`.
- **Output:** generated files written into each target tool's config
  directory. Generated files are never committed (Approach B).
- **Per-tool adapter** (`adapters/{codex,copilot,cursor}.py`) knows that
  tool's: target directories, skill placement, command handling, and
  instructions-file location, per the research matrix above.
- **Skill conversion:** copy the skill directory; rewrite frontmatter to
  the tool's required keys (`name`, `description`).
- **Command conversion:** for Cursor, strip YAML frontmatter and place
  as `~/.cursor/commands/<name>.md` (filename is the command name); for
  Codex and Copilot, wrap the command body in a generated
  `SKILL.md` (`name` from filename, `description` from the command's
  frontmatter or first line) under the tool's skills directory.
- **Path rewriting:** helper scripts are referenced via an absolute,
  tool-agnostic path under the evangelist tree; the converter rewrites
  any `~/.claude/scripts/...` reference so no converted artifact points
  at a Claude-only location.
- **`CLAUDE.md` → instructions file:** copied to each tool's
  instructions location per the matrix. Mechanical copy; Claude-specific
  passages needing rewording are left to the agent prompt.
- **Manifest:** each tool directory gets a `.convert-manifest` listing
  the files this converter generated, so a later run prunes artifacts
  whose source was deleted, without touching hand-made files.
- **Flags:** `--dry-run` (print planned writes, touch nothing),
  `--tool <name>` (scope to one tool).

### Install modes

`evangelist install ai` takes two independent choices, each either a
flag or an interactive prompt when the flag is omitted:

- `--tool codex|copilot|cursor|all` — which assistant(s) to target; a
  single tool need not drag in the other two.
- `--mode 1|2` — the migration approach (below).

Both choices are persisted under `$XDG_STATE_HOME/evangelist/`
(`ai-tool`, `ai-mode`) so `evangelist update ai` reuses them. Both
modes first do the symlink deployment above.

**Mode 1 — Scripted + finalization.** evangelist runs `convert.py` to
populate the Codex/Copilot/Cursor config directories, then renders
`prompts/finalize.md.tmpl` into a `FINALIZE.md` per tool. That prompt
instructs the target assistant to review the generated files against
the canonical Claude sources, correct anything that did not translate
cleanly, and set up MCP servers (which the converter skips). The
converter is authoritative; the agent is QA. Fast and reproducible.

**Mode 2 — Agent-driven, self-healing.** evangelist does *not* run
`convert.py`. It renders `prompts/delegate.md.tmpl` into a `DELEGATE.md`
per tool, which points the target assistant at the canonical Claude
artifacts and at `convert.py`. The prompt instructs the agent to judge
whether the converter's adapter for that tool is correct and current —
run it if sound (`python convert.py --tool <tool>`), or convert the
artifacts itself per the tool's current docs if not. Crucially, when
the agent finds the adapter stale or wrong, the prompt directs it to
**patch the adapter in place** (`convert/adapters/<tool>.py`) so the
deterministic scripts self-heal for every future run — including
Mode 1. Those edits land in the evangelist working tree for the user to
review and commit. The agent is authoritative; the scripts are a
starting point it also improves. Robust to script staleness, but
non-deterministic and token-costly.

The rendered prompt files are written to a known location (e.g.
`~/.cache/evangelist/ai-migration/<tool>/`) and their paths printed, so
the user can open the target assistant and paste them.

### Converter-refresh note

Because the other tools' files are generated (Approach B), editing a
skill or command updates Claude Code immediately (symlink) but leaves
Copilot/Codex/Cursor stale until the converter re-runs. A short note is
added to `CLAUDE.md` and `conf/ai/README.md`:

> Skills, commands, and helper scripts in `~/.claude` are
> version-controlled in `$EVANGELIST/conf/ai/claude/` (symlinked, so
> edits are already saved there). After changing any of them, run
> `evangelist update ai` to refresh the Copilot/Codex/Cursor versions.

Placing it in `CLAUDE.md` means Claude Code itself sees the reminder
whenever it edits an artifact.

### Install wiring

A new `ai` component in evangelist's `control::install` / `update` /
`uninstall`:

- `evangelist install ai [--mode 1|2]` — back up conflicting files,
  create the symlinks, then run the chosen mode.
- `evangelist update ai` — re-run the chosen mode when `conf/ai/**`
  changed (reuses evangelist's existing changed-path detection); the
  mode is remembered from install.
- `evangelist uninstall` — remove the symlinks and generated files
  (the manifest identifies the latter).

## Verify at implementation time

The research is current as of May 2026, but two items are unconfirmed
and must be checked when the adapters are written:

- **Copilot CLI `mcp-config.json`** — file name and JSON format
  confirmed; the exact top-level schema key was not verifiable. Affects
  only the prompt text, since MCP is agent-handled, not converted.
- **Cursor global skills path** — only the project-scoped
  `.cursor/skills/` is documented. If no global path exists, the Cursor
  adapter places skills per-project or the agent prompt covers it; this
  is Cursor's weakest portability surface and the adapter should degrade
  gracefully rather than fail.

## One-time audit (precedes implementation)

Before populating `conf/ai/claude/`, review the current `~/.claude`
user artifacts (4 commands, 5 skills, 2 helper scripts, statusline,
settings) and carry only what is still useful — some files may be
stale. This is a one-time cleanup, not part of any install run.

## Implementation sequencing (outline)

1. One-time audit and prune of current `~/.claude` artifacts.
2. Create `conf/ai/claude/`, move artifacts in, symlink back.
3. Build `convert.py` core + the Codex adapter (most stable target).
4. Add the Copilot and Cursor adapters.
5. Add the Mode 1 / Mode 2 prompt templates and rendering.
6. Wire the `ai` component into `control.sh` install/update/uninstall.
7. Add the converter-refresh note to `CLAUDE.md` and `README.md`.
