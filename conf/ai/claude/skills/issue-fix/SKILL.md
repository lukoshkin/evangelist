---
name: issue-fix
description: Use when asked to pick up a GitHub issue. Most common invocation is `/issue-fix <N>` or `/issue-fix #<N>` (extra context optional). Also triggers on "fix #N", "address #N", "work on issue N", "is #N done?", or a bare issue number with implied action.
---

# Fixing GitHub Issues

## Overview

When handed an issue number, the failure mode is **jumping straight to a fix
that's already shipped, or fixing the wrong half**. Before touching code:

1. **Verify the issue isn't already resolved.** A surprising number of open
   issues have shipped commits but were never closed.
2. **Read the body AND comments.** Comments often refine scope, mark deferrals,
   link sibling issues, or note that work has started elsewhere.
3. **Confirm the issue is still applicable.** Code can move out from under an
   old issue (renamed files, deleted modules, superseded design).
4. **Use the issue's Acceptance Criteria as your checklist.** Don't re-derive
   what "done" means — the filer wrote it down.

The sibling skill for creating an issue is `issue-file`.

## When to Use

- `/issue-fix <N>` or `/issue-fix #<N>` — the canonical invocation. Any extra
  context after the number is optional (hints about scope or approach).
- "fix #N", "address #N", "work on #N", "pick up #N".
- "Is #N done?" / "check if #N is resolved" — same workflow; ends at step 3
  with a close-with-evidence comment rather than a code change.
- User pastes an issue URL or a bare `#N` with implied "do this".

## Workflow

### 1. Fetch the issue (body + comments + labels)

```bash
gh issue view <N> --json number,title,state,body,labels,comments
```

**Always read the comments — not optional, even on fresh-looking issues.**
Humans and other contributors extend issues via the GitHub UI with comments,
and `issue-file` deliberately adds new info as comments rather than editing
the body. Skipping them means missing scope reductions, blockers, deferrals,
"I started this in branch foo", or a found root cause.

### 2. Is it already resolved?

Run these checks **before** planning any code change:

```bash
## (a) Commit messages referencing the issue. Project commit styles vary —
##     try several patterns. The most common in repos that follow a strict
##     convention is `Iss #<N>:` as a prefix.
git log --all --oneline --grep="#<N>\|Iss <N>\|Fixes #<N>\|Closes #<N>"

## (b) If the issue lists specific paths/symbols, grep them in current code.
##     If the code matches the issue's "after" / "fix" shape, it shipped.

## (c) Look for files the issue says to create (e.g. new migration script,
##     new endpoint, new module). If present → likely shipped.
```

**Outcomes:**

- **Already fully resolved** → don't write code. Post a close comment with
  evidence (file paths, line numbers, commit shas) and close the issue. See
  "Close comment shape" below.
- **Partially shipped** → comment with what's done vs what remains. Leave open
  unless the user says otherwise. Don't close partial work.
- **Not shipped, but the code has moved** → comment with what you found and
  ask whether the issue should be rescoped, closed as obsolete, or reopened
  against the current shape.
- **Not shipped, still applicable** → proceed to step 3.

### 3. Plan the fix

- Read every file the issue cites at the named lines.
- Treat the issue's **Acceptance criteria** (if present) as your checklist.
- For non-trivial work, use `superpowers:brainstorming` first; for multi-step
  implementation, use `superpowers:writing-plans`.
- If the issue has a "Key files" table or "Cold-start kit", use them as-is —
  don't re-discover.

### 4. Implement

- Use the project's commit-message convention. Check
  `git log --oneline -20` for the prevailing style. Common patterns:
  - `Iss #<N>: <subject>` (most informative; works with the grep above)
  - `Fix #<N>: <subject>` / `Fixes #<N>` in body (auto-closes on merge to
    default branch — be deliberate about that)
- Multi-part series: `Iss #<N> part K: <subject>` per commit.
- Reference the issue in the body too if the title doesn't.

### 5. Verify against acceptance criteria

Before claiming done, walk the acceptance list literally. If any criterion is
"tests pass" / "lint clean", run them — don't assume. (See
`superpowers:verification-before-completion`.)

### 6. Close with structured evidence

After the resolving commit(s) are merged, post a close comment with **concrete
evidence**, not just a sha. The closed issue is the historical record — make
it self-explanatory months later.

## Close comment shape

```markdown
Resolved by <sha> ("<commit title>"):
- `path/to/file.py:42` — what this commit added/changed
- `path/to/other.py:101` — second piece
- Acceptance criteria walked: [✓] tests pass, [✓] cascade verified, [✓] …
```

For multi-commit fixes:

```markdown
Resolved by:
- <sha1> — part 1: <subject>
- <sha2> — part 2: <subject>
- <sha3> — part 3: <subject>

Evidence:
- `path:line` — …
```

For "found-already-done" closes:

```markdown
Resolved — implementation landed in <sha> ("<title>"):
- <bullet of what shipped, with file:line>
- <…>
Acceptance criteria all met; closing.
```

## Authorization for closing

Auto-mode classifiers may block bulk closes when the instruction is generic.
If asked to "close them" against a list, either:

- Quote each issue number back to the user and confirm scope, OR
- Get explicit per-issue pre-authorization upfront ("if you find a clear
  resolving commit, close it with a comment referencing that commit — don't
  ask per issue").

## Common Mistakes

| Mistake | Fix |
|---|---|
| Jumping to implementation without checking if it's done | Step 2 first. Grep commits + code for the issue's named symbols. |
| Ignoring issue comments | Comments hold scope changes, blockers, deferrals. Read them. |
| Closing partial work | If only some acceptance criteria are met, comment with what's done vs what remains. Keep open. |
| One-line close comments ("done") | Use the structured shape above — file:line + sha. The closed page is the record. |
| Wrong commit-message convention | Check `git log --oneline -20` for the project's style. |
| Fixing against the issue body when the code has moved | If named files/symbols don't exist, ask whether to rescope before implementing. |
| Trying to bulk-close without explicit authorization | Quote each issue back or get blanket pre-auth first. |
| Re-deriving what "done" means | Use the issue's Acceptance criteria checklist literally. |
