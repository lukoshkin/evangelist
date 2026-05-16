---
name: socratic-learning
description: Use when the user wants a structured, multi-session learning experience on a technical topic with persistent notes and progress tracking. Triggers include "let's learn X", "teach me X", "I want to study X", "I want to study/prepare for an interview on X", explicit /socratic-learning, "resume the learning session", or when CWD already contains an INDEX.md learning corpus and the user asks "what's next" or "continue".
---

# Socratic Learning

Run a structured, multi-session learning experience for the user. Ask Socratic questions, take their answers verbatim, fill gaps, write canonical examples in their preferred language, and track progress in a persistent notes corpus.

## When to Use

- User wants to study a multi-topic curriculum (design patterns, distributed systems, ML systems, interview prep, etc.) over multiple sessions.
- User has explicit phrasings: "let's learn X", "teach me X", "I want to study X".
- CWD contains an `INDEX.md` learning corpus and the user says "continue", "resume", or "what's next?".
- Explicit `/socratic-learning` invocation.

**Don't use** for one-shot answers, casual questions, or reference lookups. This skill is for *paced, persistent* learning with a budget.

## Operating Modes

Detect mode from `ls` and `_session.md` content:

| Mode | Detected by | What to do |
|---|---|---|
| **Bootstrap** | No `INDEX.md` in CWD | Brainstorm with user, then scaffold the corpus |
| **Resume** | `INDEX.md` and `_session.md` exist; no topic is `⏳` in INDEX | Read `_session.md`, propose continuing from the suggested-next |
| **In-session** | A topic is `⏳` in INDEX | Continue the protocol from where it left off (see `_session.md` open thread) |

## Bootstrap Mode (first-time setup)

Brainstorm before scaffolding. Ask one question at a time:

1. **Topic / curriculum** — what to learn (a single topic, or a list of related topics).
2. **Style** — Lecture / Socratic / Mixed (default: mixed leaning Socratic).
3. **Language(s) for code examples** — Python only / specific language / language-agnostic.
4. **Total time budget** — e.g., 12h, 6h, "open-ended" (skip time tracking if open-ended).
5. **Initial topic ordering** — does the user have a specific list (e.g., interview question list) that drives the curriculum?

Then scaffold:

- `INDEX.md` with total budget, legend (📋/⏳/✅), per-block topic list with per-topic budgets.
- `_template.md` per-topic skeleton (see "File Conventions").
- `_session.md` initial state ("no sessions yet").
- Numbered subdirectories per block (`01-foo/`, `02-bar/`, …).
- Per-topic files are **created lazily** during sessions, not at scaffold time.

## Resume Mode

1. Read `_session.md`. Note **Open thread** and **Suggested next**.
2. State to user: "Resuming from `<open thread>`. `<topic>` is at `<step>`."
3. Continue the protocol from there.

## Session Protocol (per topic cycle)

A cycle is one topic, regardless of how many sessions it spans.

1. **Open** — If topic file doesn't exist, copy `_template.md` to `<dir>/<topic>.md` and fill the front matter. Set `Status: ⏳` in both topic file and `INDEX.md`. Ask **one** Socratic question. Include a code example if the topic warrants concrete grounding.
2. **Receive answer** — User answers freely. No grading. Don't interrupt.
3. **Append + expand** — Append to topic's `## Socratic Q&A log`: `**Q (date):**` + `**You:**` (verbatim) + `**Expansion:**`. Expansion: affirm what was right, sharpen vague terms, add what was missed, bridge to theory.
4. **Theory fill** — Write the topic's `## Theory` section: definition, structure, when-to-apply, when-NOT-to-apply.
5. **Canonical example** — Idiomatic code in the user's language. Optionally 1-2 variants if they sharpen contrast (class form vs callable form, etc.).
6. **Language considerations (optional)** — Only when the topic's shape varies meaningfully across language families. Discuss the *language property* abstractly; don't show concrete syntax in another language unless the user explicitly opted in.
7. **Pattern hunt (optional, anchor topics only)** — Find 1–3 real-code occurrences in a target codebase. Link each by `file:line`, judge as good fit / forced / misuse. Skip for non-anchor topics to stay in budget.
8. **Wrap** — Update topic file: `Status: ⏳ → ✅`, set `Time used`. Update `INDEX.md`: status icon, total time used, remaining. Rewrite `_session.md`. Offer the user three next-move options: continue to next topic, sit with this one (questions / extra forms), or pause.

## File Conventions

### Directory layout

```
<corpus-root>/
├── INDEX.md
├── _session.md
├── _template.md
├── 01-<block>/
│   ├── 00-overview.md
│   └── <topic>.md
├── 02-<block>/
│   └── ...
└── ...
```

Numeric prefixes order blocks. Underscore-prefixed meta files sort to the top.

### `_template.md`

```markdown
# <Topic name>

> One-line intent: what problem it solves.

**Time budget:** Xm · **Time used:** Ym · **Status:** 📋 / ⏳ / ✅

## Socratic Q&A log
## Theory
## Canonical example — <language>
## Language considerations (abstract)
## Pattern hunt
## Misuses & smells
## Related
```

### `INDEX.md`

```markdown
# <Track name> — curriculum

Legend: 📋 not started · ⏳ in progress · ✅ done

**Total budget:** Xh (Ym) · **Time used:** Wm · **Remaining:** Vm

## 1. <Block> (<budget>)
- 📋 [Topic 1](01-block/topic-1.md) — <budget>m
- ⏳ [Topic 2](01-block/topic-2.md) — <budget>m  *(anchor)*
- ✅ [Topic 3](01-block/topic-3.md) — <budget>m

...

**Last session:** see [`_session.md`](_session.md)
```

### `_session.md`

```markdown
# Last session — YYYY-MM-DD

**Covered:** <topic file(s)>
**Status change:** Topic 📋 → ✅
**Time spent this session:** Xm · **Total used:** Ym / Zm
**Open thread:** <one sentence — anything deferred or mid-step>
**Suggested next:** [<topic>](path/to/topic.md)
```

## Style

- **Mixed; leans Socratic.** Open with one Socratic question, expand after the user answers, lecture-fill where their answer didn't reach.
- **One question per message.** The user can only react to so much at once.
- **Affirm what's right before correcting.** Otherwise the loop becomes interrogative and tiring.
- **Verbatim answers.** Take the user's words into the Q&A log as written; their phrasing is part of the record.
- **Bias short over long for chat; long for the file.** Chat is the live teaching surface; the file is the persistent record. Don't dump full sections into chat — highlight the moves and link.

## Time Budget

`INDEX.md` carries the total; each topic file carries its slice. At Step 8 (Wrap), update both. Track approximate minutes; err slightly over to avoid overconfidence. If the budget is "open-ended," skip time tracking but keep status icons.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Dumping full topic sections into chat | Chat is the live teaching surface; highlight moves, link to file |
| 3 Socratic questions in one message | One question; let the user react |
| Skipping the affirm-before-correct move | Tires the user; hides what they got right |
| Status icons in `INDEX.md` ≠ topic file front-matter | Always update both at Wrap |
| Auto-committing | Never commit unless the user explicitly asks |
| Pattern hunt for every topic | Anchor topics only; stays within budget |
| Forgetting to update `_session.md` at Wrap | Without it, resume mode breaks next session |

## Anti-patterns

- **Java side-by-side comparisons** — see `feedback_no_java_comparison` in user/project memory if present. Default policy is Python + abstract language-property callouts only.
- **Narrative storytelling in topic files** — keep the format reusable; use the template sections.
- **Implementing the same example in 5 languages** — one excellent canonical example beats many mediocre ones. The user can port mentally.

## Cross-references

- **REQUIRED BACKGROUND** for first-time corpus setup: `superpowers:brainstorming` informs the bootstrap brainstorm style (one question at a time, propose 2–3 approaches, present design before scaffolding). For a learning corpus the brainstorm is briefer (5 questions in this skill's Bootstrap section), but the spirit is the same.
- The corpus's design spec, if the user has one, lives in `docs/superpowers/specs/` (per the `superpowers:writing-plans` convention) — read it on resume if present.
