---
name: bootstrap-project-docs
description: Use when bootstrapping a new project's documentation scaffolding, when running `/init` in a fresh repo that lacks `docs/roadmap/` or `docs/architecture/`, or when the user asks to "scaffold the project docs", "set up the roadmap structure", "init the doc folders". Creates `docs/roadmap/{README.md, phases.md}` and `docs/architecture/README.md` with self-documenting starter templates, then adds a thin pointer block to the project's `CLAUDE.md` (creating it if absent).
---

# Bootstrap Project Docs

Stamp out the canonical documentation scaffolding for a new project:

- **`docs/roadmap/README.md`** — forward-looking front page with the four
  `## Now` / `## Recently shipped` / `## Later` / `## Per-feature deferred
  work` sections (empty under self-documenting placeholders).
- **`docs/roadmap/phases.md`** — long-form, phase-by-phase handoff log for
  resuming the project cold. Populated as milestones land.
- **`docs/architecture/README.md`** — aggregator skeleton with the
  `Topic Index` table headers; topic files get added later as the design
  takes shape.
- **Project `CLAUDE.md` pointer block** — appended (or seeded fresh if no
  CLAUDE.md exists) so future Claude sessions discover the scaffolding.

The roadmap convention itself lives in the user's global CLAUDE.md
("Roadmap tracking" section). This skill is the executor that knows the
template content.

## When to Use

- User types `/bootstrap-project-docs` or asks to "scaffold the project
  docs", "set up the roadmap", "init the doc folders".
- During `/init` in a new repo: per the global CLAUDE.md convention,
  `/init` asks whether to scaffold these structures. If the user
  confirms, invoke this skill.
- After moving away from a single-file `docs/ROADMAP.md` to the folder
  form (`docs/roadmap/`): this skill bootstraps the folder shell, then
  the operator manually moves the existing content in.

## When NOT to Use

- The repo already has `docs/roadmap/README.md` AND
  `docs/architecture/README.md`. Don't re-stamp; warn the user the
  scaffolding is already present.
- The user explicitly asks to bootstrap *only one* of (roadmap,
  architecture) — write only the requested one. The skill is composable.
- For a tiny project that genuinely doesn't need the folder form, the
  user may prefer a flat `docs/ROADMAP.md`. Confirm first.

## Procedure

### Step 1: Detect existing scaffolding

Check for each target:

```sh
test -f docs/roadmap/README.md && echo "roadmap exists"
test -f docs/roadmap/phases.md && echo "phases exists"
test -f docs/architecture/README.md && echo "arch exists"
test -f CLAUDE.md && echo "CLAUDE.md exists"
```

For each that already exists, **do not overwrite**. Either skip that
target, or — if the user explicitly asked to refresh — show a diff and
ask before writing.

### Step 2: Confirm scope with the user

Before writing anything, show the user:

- The files about to be created (full paths).
- For `CLAUDE.md`: whether you'll *append* a pointer block (file
  exists) or *create* a minimal seed (file absent).
- A reminder that the templates ship empty — the user fills the
  sections as work proceeds. No project-specific content is invented.

Ask one question if anything is ambiguous (e.g., "Folder form
(`docs/roadmap/`) or flat (`docs/ROADMAP.md`)?"). Otherwise proceed.

### Step 3: Write the four artefacts

Use the templates in the next section verbatim, only substituting the
indicated placeholders.

### Step 4: Report

End with a short summary:

```
Bootstrapped:
- docs/roadmap/README.md (4 sections, all empty under placeholders)
- docs/roadmap/phases.md (header only — fill as phases land)
- docs/architecture/README.md (Topic Index empty — add rows as docs appear)
- CLAUDE.md (pointer block {created | appended})

Next:
- Drop your first roadmap entry under `## Now` when you start work.
- When you write your first architecture doc, add a row to the Topic
  Index in docs/architecture/README.md.
```

## Templates

### `docs/roadmap/README.md`

```markdown
# Roadmap

> Forward-looking status. What's in flight (`## Now`), what shipped
> recently (`## Recently shipped` — ~10 trailing entries; older
> entries fall off into `git log` and live narrative summaries in
> [`phases.md`](phases.md)), out-of-scope-but-noted ideas
> (`## Later`), and per-spec deferred work indexed under
> [`## Per-feature deferred work`](#per-feature-deferred-work).
>
> Long-form handoff context — phase summaries, decisions, the spec
> chain — lives in [`phases.md`](phases.md) (the deep dive). This
> file is the scannable front page.

## Now

<!-- Features currently being implemented. Move entries here from
`## Later` when starting fresh work, or seed straight here when work
begins. Keep to a few items so the section stays scannable. -->

## Recently shipped

<!-- Trim to ~10 trailing entries. When a milestone fully lands,
append a narrative summary to phases.md *before* dropping it off
this trim — that's how the deep context survives. -->

## Later

<!-- Out-of-scope ideas, deferred features, "v1.2 stuff". Append
silently as ideas surface mid-discussion; surface the additions in
the end-of-turn summary so the operator can prune. Remove entries
that have shipped or no longer match the codebase. -->

## Per-feature deferred work

<!-- Per-spec `v1.1` / `v1.2` / `Open items` sections stay inside
the spec docs themselves. This table just indexes where to find
them, so the roadmap doesn't duplicate spec content. -->

| Spec | Topic | Where to look |
|------|-------|---------------|
```

### `docs/roadmap/phases.md`

```markdown
# Phases — long-form handoff log

> The deep, phase-by-phase technical narrative for resuming this
> project cold: what each phase built, where the code lives, the
> key decisions made along the way.
>
> Populated as milestones land, not all at once. Distinct from the
> [roadmap front page](README.md) (which carries
> `## Now` / `## Recently shipped` / `## Later`) and from `git log`
> (raw commits): this file is the curated story.

<!-- First phase entry template (delete this comment block when
writing your first real entry):

## Phase 1 — <name>

One-paragraph summary of what shipped. Key code paths:
`src/...` , `web/...` . Decisions made and *why*. Open
follow-ups carried into the next phase.
-->
```

### `docs/architecture/README.md`

```markdown
# Architecture

<!-- 1-2 sentence overview of what this documentation set covers,
typically the load-bearing decisions and the file paths that
implement them. -->

For the current status of the project (which phase is done,
what's next), read [`docs/roadmap/README.md`](../roadmap/README.md)
first; the deeper phase-by-phase narrative is in
[`docs/roadmap/phases.md`](../roadmap/phases.md).

## Topic Index

| Topic | Description | Key Files |
|-------|-------------|-----------|
<!-- | [Example](example.html) | Brief one-line description | `src/path/to/file.py`, `src/other.py` | -->

## Convention

Topic files in this directory are authored as HTML once they have
enough structure to benefit from inline CSS, tables, collapsibles,
or inline SVG (see the user-global doc convention). Aggregator
`README.md` stays Markdown so `init-docs` / `upd-docs` can parse
the Key Files column.
```

### `CLAUDE.md` pointer block

If `CLAUDE.md` exists, **append** this block at the end (preceded by
a blank line); never overwrite or restructure existing content.

If `CLAUDE.md` is absent, **create** it with just this block (plus a
single top-of-file `# CLAUDE.md` heading and a one-line description
the user can fill in later).

```markdown
## Project documentation

- **Forward-looking status** — what's in flight, what shipped recently,
  what's deferred: [`docs/roadmap/README.md`](docs/roadmap/README.md).
- **Long-form phase-by-phase narrative** (the cold-resume handoff log,
  read this when picking up the project): [`docs/roadmap/phases.md`](docs/roadmap/phases.md).
- **Architecture docs** (mid-depth design, one topic file per
  concern): [`docs/architecture/`](docs/architecture/).
```

## Anti-Patterns

- **Don't invent project-specific content for the templates.** The
  scaffold ships empty under self-documenting placeholders; the
  operator fills sections as work proceeds. Do not pre-populate
  `## Now`, `## Recently shipped`, or `## Per-feature deferred
  work` with guesses based on the repo's current state — that's a
  separate `upd-roadmap` workflow, not bootstrap.
- **Don't overwrite an existing `docs/roadmap/README.md`,
  `phases.md`, `architecture/README.md`, or `CLAUDE.md`.** Skip the
  ones that exist, or ask the user before replacing.
- **Don't append the pointer block to a `CLAUDE.md` that already
  references `docs/roadmap/`.** Grep first; if a roadmap pointer is
  already present in any form, skip the CLAUDE.md edit.
- **Don't bootstrap into `docs/superpowers/` or any other existing
  doc subdirectory.** The folder names are conventional —
  `docs/roadmap/` and `docs/architecture/` — and not configurable.
- **Don't run `git add` or commit the new files.** Leave staging to
  the operator.
