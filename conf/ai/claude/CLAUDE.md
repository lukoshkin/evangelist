# Global preferences

## Communication

Reply in the same app the request came from unless told otherwise — a question
asked over Telegram is answered over Telegram, not left in the terminal
transcript the sender never sees. Switch channels only when explicitly
instructed.

## Plan Mode

**CRITICAL: Always create a NEW file for each new plan.** Never overwrite existing
plan files - they may contain unversioned work that took hours to create. Use
descriptive filenames like `docs/.../<feature-name>.md`.

## Documentation

When a project maintains a living architecture documentation set (typically
`docs/architecture/` with an aggregator `README.md` indexing topic-organized
files), keep it in sync with the code as you work. Whenever you add or
modify something that affects what those docs describe — load-bearing
architectural decisions, public contracts, module boundaries, data-flow
seams, persistence shape, design rationale — update the matching doc in the
same change rather than leaving the docs to drift.

Trivial work (typos, single-line bug patches, internal refactors that
preserve every external contract) does not require a doc update. Meaningful
structural changes do. If unsure whether a change qualifies, err on the
side of updating the docs; a stale architecture doc is worse than a
slightly over-eager one.

If a project has no such doc set, do not invent one — work from the code
and CLAUDE.md until the user asks for one.

## Roadmap tracking

When a project maintains a `docs/ROADMAP.md` (or
`docs/roadmap/README.md`), keep it current as you work:

- **Starting a feature:** move the entry into `## Now`.
- **Finishing a feature:** move it to `## Recently shipped` and trim
  that tail to ~10 entries; older entries live in `changelog.md` /
  `git log`.
- **Out-of-scope ideas surfacing mid-discussion** — "that's a v1.2
  thing", "we'll do that later", an extension beyond the current
  spec — append to `## Later` with a one-line summary plus a link to
  the source (spec doc, PR, transcript). Append silently; surface
  the additions in the end-of-turn summary so the user can prune.
- **Per-spec `v1.1` / `v1.2` / `Open items` sections stay inside the
  spec doc.** ROADMAP.md just indexes them under
  `## Per-feature deferred work`.
- **Maintenance:** when entries under `## Later` no longer match the
  current codebase or have shipped, remove them as part of the next
  ROADMAP edit; don't let the file grow unboundedly.

If a project has no ROADMAP.md, do not auto-create one — same rule
as the architecture-doc convention.

**On `/init` in a new repo**, ask whether to scaffold
`docs/ROADMAP.md` and `docs/architecture/` (the latter via the
`init-docs` skill). Don't create either without confirmation.

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
`/git_commit` command — it owns the full convention. Don't duplicate the rules
here.

## AI assistant config sync

Skills, commands, and helper scripts in `~/.claude` are version-controlled
in `$EVANGELIST/conf/ai/claude/` (symlinked — edits are already saved
there). After changing any of them, run `evangelist update ai` to refresh
the Copilot/Codex/Cursor versions.
