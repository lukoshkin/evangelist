Compose a commit message for the staged changes and copy it to the
clipboard. Suggest exactly one version.

## Operating rules

- Inspect staged changes with `git diff --staged --stat` and the diff to
  recall what changed. Check the last commit (`git log -1`) so the message
  reflects only the uncommitted work.
- If invoked as `/git_commit diff`, you MUST read the full staged diff with
  `git diff --staged` first and assume you know nothing from prior
  conversation.
- Running this command means I am committing now — treat any later editing
  requests as new, separate changes.
- Do NOT print the message in chat. Do NOT run `git commit`. Copy the message
  silently to the clipboard with xclip, then confirm with one short line:
  "Copied to clipboard."

## Choosing the style

1. Detect the repo's existing convention: scan
   `git log --pretty=format:'%s%n%b%n--' -30` and any commit guidance in the
   repo's CLAUDE.md / AGENTS.md / CONTRIBUTING.md.
2. If the repo has a clear, consistent convention (Conventional Commits, or
   its own format), MATCH it — that takes precedence over the House Style.
3. If history is empty, inconsistent, or has no discernible convention, use
   the House Style below.

## House Style

**Title** (always):

- Imperative mood, capitalized first word, no trailing period, aim ≤50 chars
  (≤72 hard max).
- One concrete summary of the main change. Generic titles ("Bug fixes",
  "Small improvements") only when the commit truly is a grab-bag of unrelated
  small changes.
- Optional status prefix for incomplete work: `UNFINISHED: …`, `WIP: …`.
- Disambiguate a repeated title with a counter: `Bug fixes (2)`.

**Body** — pick the lightest mode that fits; scale verbosity to change size:

- *No body* — a small, single-purpose change. Most one-file / few-line
  commits need only a title.
- *Prose body* — 1–4 full sentences when the change needs a "why": the bug
  and its cause, or the rationale. No bullets.
- *Bulleted body* — for multi-change commits. Each bullet: symbol + space,
  imperative mood, ends with a period; wrap continuation lines indented under
  the text.

**Symbols:**

- `+` improvement / new feature
- `-` removal / deletion
- `c` change — refactor, rename, chore
- `*` bug fix (functional, performance, anything broken)
- `▪` sub-bullet for detail under another bullet
- Combine symbols when one bullet genuinely spans categories: `*+`, `c+`,
  `*+c`. Use sparingly.

**Grouping:**

- Group related bullets under a `Header:` line (ends with a colon) — a
  filename, component, or `Minor:` / `Also,`.
- Nest detail with 2-space indentation: sub-bullets (any symbol or `▪`) or
  numbered lists.
- Inline annotations allowed: `[TODO]`, `(UNFINISHED PART: …)`, parenthetical
  rationale.

**Quoting (three tiers):**

- `'single quotes'` — file paths and filenames.
- `` `backticks` `` — code symbols: functions, classes, methods, variables,
  config keys.
- `"double quotes"` — everything else quoted: task / stage names, states.

**Examples:**

Small change — title only:

```
Apply timeout directly to Redshift query execution
```

Multi-change — grouped bulleted body:

```
Improve CloudWatch logs
+ Add tests for the added logger filters.
+ Use the fixed name (specified by the "tag") for all log streams.
+ Suppress warnings that are not relevant to the app operation
  * Prometheus warnings when logging an unregistered metric.
  * Lego's Milvus DB warnings about unordered embeddings.
  since we OK with that.
```
