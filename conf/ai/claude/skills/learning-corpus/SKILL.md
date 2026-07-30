---
name: learning-corpus
description: Shared mechanics for a browsable, structured learning-notes corpus (INDEX.md + numbered topic folders + pandoc-rendered HTML viewer). Callers (lvlup-session, socratic-learning) supply their own topic content; this skill only handles scaffolding, registration, writes, and rendering. Invoke via /learning-corpus <init|add-topic|update-topic|render> ...args, or by another skill's own procedure calling the same operations.
---

# Learning Corpus

Shared corpus mechanics for any skill that wants to persist structured
learning material as a browsable static site. Owns file layout, `INDEX.md`
bookkeeping, and HTML rendering. Does **not** own topic content — callers
render their own markdown body and hand it to `update-topic`.

## Status vocabulary

Four states, fixed:

| Status | Icon |
|---|---|
| `pending` | 📋 |
| `in_progress` | ⏳ |
| `needs_review` | ⚠️ |
| `done` | ✅ |

## Corpus shape

```
<corpus-root>/
├── INDEX.md
├── index.html            (generated)
├── build_viewer.py        (copied once, at init)
├── _session.md / .html
├── _assets/
│   └── style.css          (copied once, at init)
└── NN-<slug>/
    └── 00-overview.md     (+ 00-overview.html once rendered)
```

One numbered folder per topic, flat — no group-level nesting. `NN` is a
zero-padded, monotonically increasing two-digit number, assigned in
registration order.

## OPERATION: `init <corpus-root> [--title <title>] [--source <line>]`

**Idempotent** — if `<corpus-root>/INDEX.md` already exists, do nothing and
report "Corpus already initialized at `<corpus-root>`."

Otherwise:

1. Create `<corpus-root>/_assets/` if it doesn't exist.
2. Copy this skill's `assets/style.css` to `<corpus-root>/_assets/style.css`.
3. Copy this skill's `assets/build_viewer.py` to `<corpus-root>/build_viewer.py`.
4. Write `<corpus-root>/_session.md`:
   ```
   # Session Log

   (no sessions yet)
   ```
5. Write `<corpus-root>/INDEX.md`:
   ```
   # <title, or "Learning Corpus" if not given>

   Legend: 📋 pending · ⏳ in progress · ⚠️ needs review · ✅ done

   <the --source line verbatim, if given, else omit this line>
   ```
6. Report: "Initialized corpus at `<corpus-root>`."

## OPERATION: `add-topic <corpus-root> <slug> <title> [--body <markdown>]`

<!-- filled in Task 3 -->

## OPERATION: `update-topic <corpus-root> <slug> <content> --status <pending|in_progress|needs_review|done>`

<!-- filled in Task 4 -->

## OPERATION: `render <corpus-root>`

<!-- filled in Task 5 -->
