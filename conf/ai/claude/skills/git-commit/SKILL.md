---
name: git-commit
description: Use when the user asks to create a git commit, commit current work, or prepare a commit from staged changes. Inspects the relevant diff, writes one commit message matching the repository convention, and runs git commit.
---

# Git Commit

Create a git commit with a concise, repository-appropriate message.

## Operating Rules

- Inspect the worktree before changing anything:
  - `git status --short`
  - `git diff --staged --stat`
  - `git diff --stat`
- If the user asks to commit staged changes, commit only what is already staged.
- If the user asks to commit your current work, stage only the files you changed
  for the task. Do not stage unrelated user changes.
- Read the staged diff before committing:
  - `git diff --staged`
- Check the last commit with `git log -1 --stat` so the new message reflects
  only the current staged work.
- If there are no staged changes after the requested staging step, stop and
  report that there is nothing to commit.
- If staged changes include files unrelated to the requested commit, stop and
  ask how to proceed instead of silently committing them.
- Create exactly one commit unless the user explicitly asks for multiple
  commits.
- Run `git commit` with the selected message. Afterward, report the commit hash
  and title.

## Choosing The Style

1. Detect the repo's existing convention: scan
   `git log --pretty=format:'%s%n%b%n--' -30` and any commit guidance in the
   repo's CLAUDE.md / AGENTS.md / CONTRIBUTING.md.
2. If the repo has a clear, consistent convention (Conventional Commits, or
   its own format), match it. Repository convention takes precedence over the
   House Style.
3. If history is empty, inconsistent, or has no discernible convention, use the
   House Style below.

## House Style

**Title** (always):

- Imperative mood, capitalized first word, no trailing period, aim <=50 chars
  (<=72 hard max).
- One concrete summary of the main change. Generic titles ("Bug fixes",
  "Small improvements") only when the commit truly is a grab-bag of unrelated
  small changes.
- Optional status prefix for incomplete work: `UNFINISHED: ...`, `WIP: ...`.
- Disambiguate a repeated title with a counter: `Bug fixes (2)`.

**Body** - pick the lightest mode that fits; scale verbosity to change size:

- *No body* - a small, single-purpose change. Most one-file / few-line commits
  need only a title.
- *Prose body* - 1-4 full sentences when the change needs a "why": the bug and
  its cause, or the rationale. No bullets.
- *Bulleted body* - for multi-change commits. Each bullet: symbol + space,
  imperative mood, ends with a period; wrap continuation lines indented under
  the text.

**Symbols:**

- `+` improvement / new feature
- `-` removal / deletion
- `c` change - refactor, rename, chore
- `*` bug fix (functional, performance, anything broken)
- `▪` sub-bullet for detail under another bullet
- Combine symbols when one bullet genuinely spans categories: `*+`, `c+`,
  `*+c`. Use sparingly.

**Grouping:**

- Group related bullets under a `Header:` line (ends with a colon) - a
  filename, component, or `Minor:` / `Also,`.
- Nest detail with 2-space indentation: sub-bullets (any symbol or `▪`) or
  numbered lists.
- Inline annotations allowed: `[TODO]`, `(UNFINISHED PART: ...)`, parenthetical
  rationale.

**Quoting (three tiers):**

- `'single quotes'` - file paths and filenames.
- `` `backticks` `` - code symbols: functions, classes, methods, variables,
  config keys.
- `"double quotes"` - everything else quoted: task / stage names, states.

**Examples:**

Small change - title only:

```text
Apply timeout directly to Redshift query execution
```

Multi-change - grouped bulleted body:

```text
Improve CloudWatch logs
+ Add tests for the added logger filters.
+ Use the fixed name (specified by the "tag") for all log streams.
+ Suppress warnings that are not relevant to the app operation
  * Prometheus warnings when logging an unregistered metric.
  * Lego's Milvus DB warnings about unordered embeddings.
  since we OK with that.
```
