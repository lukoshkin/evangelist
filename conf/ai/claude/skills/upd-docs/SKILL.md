---
name: upd-docs
description: Use when updating project documentation after code changes — maps changed source files to relevant docs via aggregator indexes, then dispatches parallel agents to update each doc. Requires README.md aggregators with Key Files columns in each docs subdirectory.
---

# Update Docs

Update project documentation based on code changes in a commit range.

## Input

Same commit range formats as `/changelog`:

1. **Tag to tag**: `v1.0.0..v1.1.0`
2. **Commit to HEAD**: `abc1234..HEAD` or `v1.0.0..HEAD`
3. **Last N commits**: `~N` or "last 20 commits"

## Aggregator Requirement

Each documentation subdirectory must have a `README.md` aggregator with a table containing a **Key Files** column that maps docs to source paths:

```markdown
| Topic | Description | Key Files |
|-------|-------------|-----------|
| [Task Scoring](task-scoring.md) | ... | `src/features/tasks/selection_algorithms.py`, `priority_scorer.py` |
```

**Discovery:** scan `docs/*/README.md` for aggregators containing a table with a Key Files column.

**Opt-in via aggregator:** only directories whose README.md has a valid Key Files table are processed. All other `docs/*/` subdirectories (plans, artifacts, etc.) are silently ignored — no warnings, no prompts.

**If zero valid aggregators found:** stop and tell the user:
> "No aggregator README.md with Key Files mapping found in any `docs/*/` directory. Create one manually or with `/init-docs` before running `/upd-docs`."

Do NOT proceed without aggregators — guessing file-to-doc mappings leads to missed or wrong updates.

## Procedure

### Step 1: Discover and Parse

1. `git diff --stat <range> -- src/` → list of changed source files
2. `git diff --diff-filter=RADC --name-status <range>` → detect renames (R), additions (A), deletions (D), and copies (C) across the entire repo
3. Read each `docs/*/README.md` aggregator
4. Parse the Key Files column from each table row
5. Match changed source files against Key Files entries (prefix match: `src/features/tasks/` matches `src/features/tasks/selection_algorithms.py`)
6. Flag filesystem changes that affect aggregators:
   - **Renamed/moved source files** — if an old path appears in any Key Files column, flag it for path update
   - **New source files** — if a new `src/` file doesn't match any existing Key Files entry, flag it as potentially unmapped
   - **Deleted source files** — if a deleted path appears in Key Files, flag it for removal
   - **New doc files in `docs/*/`** — flag for adding a row to the aggregator
   - **Renamed/moved doc files** — flag for updating aggregator links
   - **Deleted doc files** — flag for removing the aggregator row

### Step 2: Present Candidates

Show the user a table of matched docs and aggregator changes before proceeding:

```
Docs to update (based on changed files in <range>):

  docs/architecture/task-scoring.md        — 5 files matched
  docs/architecture/llm-pipeline.md        — 3 files matched
  docs/architecture/tool-filtering.md      — 1 file matched
  docs/app-usage/tasks.md                  — 2 files matched

  Skipped (no matched files): 18 docs

Aggregator maintenance:
  ~ Key Files path update: src/old/path.py → src/new/path.py (in task-scoring.md row)
  + New source file not mapped: src/features/tasks/new_module.py
  + New doc needs aggregator row: docs/architecture/new-topic.md
  - Deleted source file to remove: src/features/old_module.py (from tool-filtering.md row)

Proceed with all, or pick specific ones?
```

Wait for user confirmation. They may want to skip some or add others.

### Step 3: Parallel Update

Dispatch up to **5 agents per batch**. If more than 5 docs need updating, process in batches — wait for the current batch to complete before dispatching the next. This avoids API rate limits and keeps resource usage manageable.

For each confirmed doc, dispatch a parallel agent (use the Agent tool with multiple calls in one message). Each agent receives:

1. **The doc to update** — full current content
2. **The relevant diffs** — only the diffs for files mapped to this doc (`git diff <range> -- <matched files>`)
3. **The commit messages** — for the commits that touched matched files
4. **Update instructions:**
   - Read the current doc structure and maintain it
   - Update sections that are affected by the diffs
   - Add new sections only if a significant new feature/concept was introduced
   - Remove or correct outdated information
   - Do NOT rewrite sections unrelated to the changes
   - Keep the doc's existing style and level of detail
   - If a code snippet in the doc is outdated, update it to match current code

### Step 4: Update Aggregators

After updating individual docs, apply the aggregator maintenance flagged in Step 2:

**Key Files path maintenance:**
- Renamed/moved source files → update paths in Key Files columns
- Deleted source files → remove from Key Files columns
- New source files → suggest which doc row they belong to (based on directory/feature)

**Doc file maintenance:**
- New doc files in `docs/*/` → add a row to the appropriate aggregator (Topic, Description, Key Files)
- Renamed/moved doc files → update links in aggregator rows
- Deleted doc files → remove the row from the aggregator

**Content maintenance:**
- Description column outdated after doc updates? → update to match
- Key Files column incomplete after new features? → add missing paths

Present all aggregator changes to the user for confirmation before applying.

## Scope Rules

- **Commit messages + diffs are the primary source.** Only read actual source files when a diff is ambiguous or a commit message is too terse to understand the change.
- **Don't update docs for pure bug fixes** unless the bug fix changed documented behavior.
- **Don't update docs for refactors** (renamed internals, moved code) unless the doc references the old names/paths.
- **Architecture docs** describe how things work technically — update when behavior, APIs, data models, or algorithms change.
- **App-usage docs** describe what users can do — update when commands, UI flows, or user-visible behavior changes.

## Anti-Patterns

- **Don't proceed without aggregators.** The whole point is systematic mapping, not guessing.
- **Don't update all docs sequentially.** Use parallel agents — each doc is independent.
- **Don't read source code upfront.** Diffs tell you what changed; source code is for when you need full context around a change.
- **Don't silently skip docs.** Show the user what's being skipped and why.
- **Don't rewrite docs from scratch.** Surgical updates to affected sections only.
