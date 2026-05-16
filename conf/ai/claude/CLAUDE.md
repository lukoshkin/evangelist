# Global preferences

## Plan Mode

**CRITICAL: Always create a NEW file for each new plan.** Never overwrite existing
plan files - they may contain unversioned work that took hours to create. Use
descriptive filenames like `docs/plans/<feature-name>.md`.

## Subagent Workflow

When dispatched as a subagent by `superpowers:subagent-driven-development` in a
**Python project**, run the project's code-quality skill (e.g.
`ensure_code_quality` if the project's CLAUDE.md defines one) on every Python
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

## Commit Message Guidelines

Follow this exact style and format for all commit messages:

**STRUCTURE:**

1. **Title**: Brief, imperative mood description of the main change (50-72 chars)
2. **Body**: Concise, organized, bullet-pointed changes using specific symbols

**SYMBOLS:**

- `+` = Improvements/new features
- `-` = Removals/deletions of files or functionality
- `c` = Changes like refactoring and chore tasks
- `*` = Bug fixes (functional, non-functional, performance)
- `▪` = Sub-bullets for detailed explanations

**FORMATTING RULES:**

1. Adjust verbosity based on the amount of changes made (a few lines changed = short commit)
2. Group related changes under descriptive section headers when there are a lot of changes
3. Start each bullet with the appropriate symbol, followed by a space
4. Write in imperative mood (Add, Remove, Fix, Update, etc.)
5. Mention specific files, functions, or settings when relevant
6. Use '' for file paths, `` for code symbols, and "" for other quoted text
7. Use proper indentation for sub-bullets

**EXAMPLES:**

Simple case:

```
Short title

+ Add new feature with specific technical details
- Remove deprecated functionality (reason why)
c Refactor existing code for better performance
* Fix bug in specific component
  ▪ Add sub-detail about implementation
  ▪ Explain technical rationale
```

Complex case:

```
Short title

Section header:
+ Add a specific pipeline:
  ▪ The first feature that enables pipeline implementation.
  ▪ The second feature.
c Refactor 'ExistingModule':
  c Change variable names for clarity.
  + Simplify complex functions.
  + Improve robustness.
  - Remove redundant and duplicated code.

Second section with stuff that related some other functionality:
...
```

## AI assistant config sync

Skills, commands, and helper scripts in `~/.claude` are version-controlled
in `$EVANGELIST/conf/ai/claude/` (symlinked — edits are already saved
there). After changing any of them, run `evangelist update ai` to refresh
the Copilot/Codex/Cursor versions.
