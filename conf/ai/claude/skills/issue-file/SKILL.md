---
name: issue-file
description: Use when asked to file/open/create a GitHub issue. Supports `/issue-file <description> [media]` (order arbitrary) for one-shot creation, or free-form requests like "write an issue for this", "log a bug", "open a ticket", "capture this for a fresh session".
---

# Filing GitHub Issues

## Overview

An issue is a **cold-start brief**: it must let a fresh session (no memory of
this conversation) pick up the work and ship it. Ground every claim in the
code, attach what you saw, write checkable acceptance criteria, and point at
the resolution convention. The detailed close protocol lives in the sibling
skill `issue-fix`.

## When to Use

- `/issue-file <desc> [media]` (or `/issue-file <media> <desc>` — order is
  arbitrary). Treat any text + attachment combo as a one-shot create request.
- "File / open / create an issue", "write an issue for this", "log a bug".
- One report covers several independent surfaces → **one issue each**. Ask only
  if combine-vs-split is genuinely ambiguous.

## Workflow

1. **Check first.** `gh issue list --search "<keywords>"` (catch dupes — plain
   `gh issue list` only paginates recent). Identify any sibling issues to
   cross-link (`#NN — short reason`). `gh label list` for a label that exists
   (`bug` / `enhancement`); never invent one.
2. **Explore the repo for Key Files.** Read the files implicated by the
   description. Cite `file.ext:line`. The Key Files table is the single biggest
   accelerator for a fresh-session pickup — fill it in even if the issue is
   small.
3. **Extract session-bound details into the body.** Anything in this
   conversation that isn't in the code: reproduction steps, observed behavior,
   screenshots, logs, user-reported context. The fresh session won't have it
   unless the issue does.
4. **Create + attach + finalize.** Number isn't known until creation, so:
   - `gh issue create --label <l> --title "…" --body "stub"` → read `<NNN>`.
   - `mkdir -p .github/issue-assets/<NNN>/`, copy assets in with descriptive
     names, `git add` + commit (so a fresh checkout has them).
   - `gh issue edit <NNN> --body-file …` with the real body referencing the
     asset paths.
5. **Report** the issue URL.

## Issue body template

```markdown
## Summary
One paragraph: what's wrong / wanted. **Screenshot:** `.github/issue-assets/<NNN>/<name>.png`

## Steps to reproduce
1. … 2. … 3. …
**Expected:** …  **Actual:** …

## Grounding
### Verified facts (read from the code)
- `path:line` — what the code actually does.
### Hypothesis (needs confirmation)
- Most likely cause + how to confirm. Flag theories ruled out.

## Key files
| Path | Role |
|---|---|
| `src/foo.py:42` | … |
| `tests/test_foo.py` | … |

## Run / test commands
- `<build>` · `<run>` · `<tests>` · `<lint>` — exact commands.

## Acceptance criteria
- [ ] Concrete, checkable conditions. A future triager (not just the
  implementer) reads these to decide "is this done?" without re-deriving
  the spec.

## Fix directions
- Concrete options the implementer can evaluate.

## References
- `#NN` — sibling issue / blocker / superseded-by.
- `docs/architecture/<topic>.md` — relevant architecture doc.

## Resolution
Reference this issue in the fix commit (e.g. `Iss #<NNN>: <subject>` —
check `git log --oneline -20` for the repo's convention). After merge,
close `#<NNN>` with a comment naming the resolving commit(s). Full
protocol: see the `issue-fix` skill.
```

## Extending an existing issue

When new info arrives after the issue is created (more repro detail, a
related symptom, a found root cause), **add a comment via `gh issue comment
<NNN>`** — don't edit the body. Reasons:

- Comments preserve the audit trail (who said what when).
- Humans + other contributors extend issues via the GitHub UI with comments;
  consistency keeps the timeline coherent.
- The body should remain the original cold-start brief — let comments hold the
  delta.

Edit the body only to fix mistakes in the original (typos, broken links,
wrong line numbers).

## Common Mistakes

| Mistake | Fix |
|---|---|
| Restating the symptom only | Open the code, cite `file:line`. |
| Overclaiming the root cause | Mark it a hypothesis; give a way to confirm. |
| Dropping the user's screenshot | Save to `.github/issue-assets/<NNN>/`, commit, reference it. |
| Inventing a label | Only use labels from `gh label list`. |
| Bundling unrelated problems | One issue per independent surface. |
| Vague acceptance ("works correctly") | Make each criterion checkable in code or a log line. |
| Editing the body to add new info | Use a comment — preserves the timeline. |
| No cross-links to siblings | Reference related issues + specs. |
