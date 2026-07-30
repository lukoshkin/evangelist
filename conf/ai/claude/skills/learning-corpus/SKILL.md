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

**Idempotent per slug** — if a folder matching `<corpus-root>/[0-9][0-9]-<slug>`
already exists, do nothing and report "Topic `<slug>` already registered."

Otherwise:

1. Count existing `## ` headers in `<corpus-root>/INDEX.md` → `count`. Next
   number `N = count + 1`, zero-padded to 2 digits (`01`, `02`, ... `10`, ...).
2. Create `<corpus-root>/<N>-<slug>/`.
3. Write `<corpus-root>/<N>-<slug>/00-overview.md`:
   ```
   # <title>

   **Status:** 📋 pending

   <--body content verbatim, or nothing if not given>
   ```
4. Append to `<corpus-root>/INDEX.md`:
   ```

   ## <N (unpadded)>. <title>
   - 📋 [<title>](<N>-<slug>/00-overview.md)
   ```
5. Report: "Added topic `<slug>` as `<N>-<slug>/`."

## OPERATION: `update-topic <corpus-root> <slug> <content> --status <pending|in_progress|needs_review|done>`

1. Glob `<corpus-root>/[0-9][0-9]-<slug>`. If no match, error: "Topic `<slug>`
   not registered — call add-topic first." Do not create it implicitly.
2. Read the existing `00-overview.md`'s first line (`# <title>`) to preserve
   the title exactly as `add-topic` set it.
3. Map `--status` to its icon: `pending`→📋, `in_progress`→⏳,
   `needs_review`→⚠️, `done`→✅.
4. Overwrite `00-overview.md`:
   ```
   # <title, preserved from step 2>

   **Status:** <icon> <status>

   <content, verbatim>
   ```
5. In `INDEX.md`, find the bullet line whose path is
   `<N>-<slug>/00-overview.md` and replace its leading icon (the first
   `\S+` token after `- `) with the new icon from step 3. Leave the rest of
   the line (title, trailing text) untouched.
6. Report: "Updated topic `<slug>` (status: `<status>`)."

## OPERATION: `render <corpus-root>`

<!-- filled in Task 5 -->
