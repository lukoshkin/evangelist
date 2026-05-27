# Global preferences

## Communication

Reply through the channel the request came from. Each channel's readers
only see that channel; routing your answer elsewhere is the same as not
answering them — silent failure, no signal back.

The reply channel is chosen **per inbound message**, by looking at THIS
message's `<channel>` tag (or absence). Channel context does not persist
across turns — earlier requests like "let's move to Telegram" or
"answer in the terminal from now on" do not override a later message's
own channel signal.

- **No `<channel>` tag on the inbound message** → terminal Claude Code
  session. Write text output normally; that's what the user reads in
  the REPL. Do not use any reply tool.
- **Inbound has `<channel source="...">`** → use that plugin's reply
  tool (e.g. `mcp__plugin_telegram_telegram__reply`), passing the
  inbound `chat_id` (or equivalent identifier) back. Terminal stdout is
  invisible to that reader.
- **Mid-task arrivals on a different channel** → treat as separate
  conversations. Reply to the new message in its channel; continue any
  existing task in its own channel. Do not merge transcripts.

If you find yourself reaching for a reply tool because "we've been on
channel X for a while", stop and re-check the latest inbound's
`<channel>` tag. The tag (or its absence) is the authoritative source.

Switch the *durable* channel only when explicitly instructed ("move
this to Telegram from now on", "answer in the terminal from here on").
Even then, individual later messages still route by their own tag.

## Plan Mode

**CRITICAL: Always create a NEW file for each new plan.** Never overwrite existing
plan files - they may contain unversioned work that took hours to create. Use
descriptive filenames like `docs/.../<feature-name>.md`.

## Documentation

When a project maintains a living user-facing documentation set about the
app — typically `docs/architecture/` for design and `docs/app-usage/` for
end-user behavior, each with an aggregator `README.md` indexing
topic-organized `.html` files — keep it in sync with the code as you work.
Whenever you add or modify something that affects what those docs describe
— load-bearing architectural decisions, public contracts, module
boundaries, data-flow seams, persistence shape, design rationale,
observable app behavior — update the matching doc in the same change rather
than leaving the docs to drift.

**Format.** Topic files under user-facing app-doc roots (e.g.
`docs/architecture/`, `docs/app-usage/`) are authored as `.html`, not
Markdown — HTML supports tables with CSS, inline SVG, collapsible
sections, and side-by-side panes, and stays readable past the ~100-line
point where dense Markdown breaks down. Use self-contained inline CSS
(no external stylesheets, no build step) so a single file is the unit of
share. Aggregator `README.md` files stay Markdown so `init-docs` /
`upd-docs` can parse the Key Files table. New topic files: `.html`;
existing `.md` topic files stay as-is until a substantive update, then
convert in the same change.

The HTML rule does **not** extend to: plan files under `docs/plans/`,
`docs/ROADMAP.md`, project or subdirectory `README.md` (GitHub renders
those natively as landing pages — that convention wins), or files the
harness requires in Markdown (`CLAUDE.md`, `AGENTS.md`, `SKILL.md`).
Rationale:
<https://claude.com/blog/using-claude-code-the-unreasonable-effectiveness-of-html>.

Trivial work (typos, single-line bug patches, internal refactors that
preserve every external contract) does not require a doc update. Meaningful
structural changes do. If unsure whether a change qualifies, err on the
side of updating the docs; a stale architecture doc is worse than a
slightly over-eager one.

If a project has no such doc set, do not invent one — work from the code
and CLAUDE.md until the user asks for one.

## Roadmap tracking

When a project maintains a roadmap, keep it current as you work.
Two shapes are supported — pick by project size:

- **Folder form (recommended once a project has phase history).**
  `docs/roadmap/README.md` is the scannable forward-looking front
  page (the four `##` sections below). `docs/roadmap/phases.md`
  is the long-form, phase-by-phase technical narrative — the
  cold-resume handoff log: what each phase built, where the code
  lives, the decisions made along the way. Distinct from
  `## Recently shipped` (curated trim of ~10) and `git log` (raw
  commit history): `phases.md` is the curated story.
- **Flat form (small or brand-new projects).** A single
  `docs/ROADMAP.md` carrying just the four `##` sections. Promote
  to the folder form once the phase-by-phase narrative would start
  bloating the trailing-10 trim.

Rules (apply to either shape):

- **Starting a feature:** move the entry into `## Now`.
- **Finishing a feature:** move it to `## Recently shipped` and trim
  that tail to ~10 entries; older entries fall off into `git log` /
  `changelog.md`. **Folder form:** when a milestone fully ships,
  append a narrative summary to `phases.md` before letting the
  trim drop the entry, so the deep context survives.
- **Out-of-scope ideas surfacing mid-discussion** — "that's a v1.2
  thing", "we'll do that later", an extension beyond the current
  spec — append to `## Later` with a one-line summary plus a link to
  the source (spec doc, PR, transcript). Append silently; surface
  the additions in the end-of-turn summary so the user can prune.
- **Per-spec `v1.1` / `v1.2` / `Open items` sections stay inside the
  spec doc.** The roadmap's `## Per-feature deferred work` is a
  table indexing those sections, not duplicating them.
- **Maintenance:** when entries under `## Later` no longer match the
  current codebase or have shipped, remove them as part of the next
  roadmap edit; don't let the file grow unboundedly.

If a project has no roadmap, do not auto-create one — same rule
as the architecture-doc convention.

**On `/init` in a new repo**, ask whether to scaffold the roadmap
(folder form by default — fall back to flat `docs/ROADMAP.md` only
if the user prefers it) and `docs/architecture/` (the latter via
the `init-docs` skill). Don't create either without confirmation.

The scaffolded `docs/roadmap/README.md` should ship with the four
`##` sections empty under one-line descriptions of what each
section means (so the structure is self-documenting). The
scaffolded `docs/roadmap/phases.md` should ship as a short header
explaining that it's the long-form, phase-by-phase handoff log
for resuming the project cold — populated as milestones land, not
all at once.

## Subagent Workflow

When dispatched as a subagent by `superpowers:subagent-driven-development` in a
**Python project**, run the project's code-quality skill (e.g.
`ensure-code-quality` if the project's CLAUDE.md defines one) on every Python
file you touched before reporting the task complete. If the project defines no
such skill, run `ruff check` and `mypy` on the touched files. This applies to
all subagent types (general-purpose, Explore, feature-dev, code-simplifier,
etc.) when they make code changes.

The check belongs in the subagent's context — that's where the changes
happened and where the file list is freshest. Do not defer it to the parent.

**Model selection for dispatched agents**: Never delegate Python work to
Haiku. Use Sonnet or Opus only. Haiku produces plausible-looking but subtly
wrong Python code that passes tests but fails review.

## Efficiency

For bulk renaming use sed/awk/python scripts **only when the replacement is
unconditionally safe** — e.g., a unique symbol name, a config key that appears
nowhere else, or an import path with no substring collisions. When a token
appears in multiple semantic contexts (common words, short names, names that
are substrings of other identifiers), use the Edit tool per-file instead so
each occurrence is verified in context. When unsure, prefer Edit.
Before running a scripted replacement, `git add` the affected files so the
diff is easy to review with `git diff --cached` afterward.

Leave formatting to ruff (the human runs it) and tests to the human (the
environment may not be fully set up in Claude's session).

## MCP Tools

### Context7

Use Context7 to fetch the latest documentation, SDK and API references, and
relevant code examples for a particular library or framework. But mind
specifying the latest versions, otherwise, it may get harmful for the
development

## Development Commands

**Docker-first rule:** If a project has Docker set up, **always** use
`docker compose exec` (or `docker exec`) to run Python, tests, linters, etc.
**Never** run `uv run`, `uv sync`, `pip install`, or any dependency-resolving
command locally in a Dockerized project.

## Code Style Conventions

### Redundant safety

1. Stop wrapping everything with try-except block and catching general exceptions
\- this does not help. In opposite, this make things much worse: instead of
handling errors, you discard them silently -- THIS IS BAD. If you know which
error to catch and know how to deal with it - then add it. Otherwise, just
go without try-except wrapping.
2. Stop using `.get()` when it is not necessary. Access values with
   `__getitem__` operator `[]` when the item is there. That is, make a check we
have the item and use `[]`. And ONLY when the dict may not contain or the
function returns union with None (it is about checking on None), ONLY then
we use `.get` or check on None

### Formatting

- Imports should be at the top of the module whenever possible. Exceptions include dynamic imports using importlib and imports within the `__main__` clause
- Write comments only when the code's purpose isn't immediately clear. Well-written code should be self-explanatory in most cases
- Use the walrus operator (`:=`) when it improves code readability
- **Leave line length to ruff** — don't manually count characters or wrap lines to a fixed width; the formatter owns this
- Use ruff for formatting and linting. Prefer `uv tool run` (or its alias
  `uvx`) so ruff runs in an ephemeral env — no main project deps, no
  `--only-group dev` syncing, no cold-install hit:
  - Format: `uv tool run ruff format`
  - Lint: `uv tool run ruff check --fix`
  In Dockerized projects, run ruff inside the container instead:
  `docker compose exec -T <svc> uv run --only-group dev ruff check --fix`.
  Avoid bare `uv run ruff ...` — that resolves the full project deps.
- NumPy docstring convention for documentation
- **Prefer multiline strings** for long text instead of concatenation
- **Avoid deeply nested functions** - prefer flat, readable code structure.
  Divide complex functionality into helper functions/methods. Use early returns
- **No trailing commas** — they force ruff to always spread code vertically regardless of line length

### Type Hints

- **Required**: All function signatures must have type hints
- Use built-in generics (`list[str]`, `dict[str, int]`, `X | Y`) for Python 3.10+
- Use `from typing import` only for `TypeVar`, `Protocol`, `Literal`, `TypeAlias`, etc.
- `mypy` strict mode enabled (except for tests)

## Commit Messages

For commit-message style (House Style, symbols, grouping, examples), use the
`git-commit` skill — it owns the full convention. Don't duplicate the rules
here.

## AI assistant config sync

Skills, commands, and helper scripts in `~/.claude` are version-controlled
in `$EVANGELIST/conf/ai/claude/` (symlinked — edits are already saved
there). After changing any of them, run `evangelist update ai` to refresh
the Copilot/Codex/Cursor versions.
