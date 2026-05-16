---
name: init-docs
description: Use when a docs subdirectory lacks an aggregator README.md with a Key Files column, or when setting up documentation structure for a new doc category. Prerequisite for /upd-docs.
---

# Init Docs

Generate aggregator README.md files for documentation directories that lack one.

## When to Use

- Before running `/upd-docs` when it reports missing aggregators
- When creating a new documentation category (e.g., `docs/api-reference/`)
- When an existing README.md lacks the Key Files column needed by `/upd-docs`

## Input

The user specifies which `docs/*/` directory to initialize. If none specified, scan all `docs/*/` directories and offer to initialize those missing a valid aggregator.

## Procedure

### Step 1: Scan Directory

1. List all `.md` files in the target `docs/<dir>/` (excluding README.md itself)
2. For each doc file, extract Key Files candidates:
   - **Primary:** read the doc and collect backtick-quoted source paths (e.g., `` `src/features/tasks/tools.py` ``)
   - **Secondary:** use naming heuristics as fallback — `tasks.md` → search for `src/features/tasks/`, `src/interfaces/aiogram/routers/tasks.py`, etc.
   - **Tertiary:** `grep -rl` for the doc's topic keywords in `src/` to find related files
3. Deduplicate and validate: confirm each candidate path actually exists on disk

### Step 2: Generate Aggregator

Build the README.md with this structure:

```markdown
# <Directory Title>

<1-2 sentence overview of what this documentation covers.>

## Topic Index

| Topic | Description | Key Files |
|-------|-------------|-----------|
| [Doc Name](doc-name.md) | Brief description | `src/path/to/file.py`, `src/path/to/other.py` |
```

**Description column:** extract from the doc's first heading or opening paragraph — keep to one line.

**Key Files column:**
- Use specific file paths when the doc covers a narrow scope
- Use directory paths with trailing `/` when the doc covers an entire module (e.g., `src/features/delegates/`)
- List the most relevant 2-5 files; don't exhaustively list every file

### Step 3: Present for Review

Show the generated README.md to the user **before writing**. They may want to:
- Adjust Key Files mappings
- Reword descriptions
- Add/remove rows
- Add additional sections (Quick Reference, etc.)

Only write the file after user confirmation.

## Existing README.md

If a README.md already exists but lacks Key Files:
- Preserve ALL existing content (overview, diagrams, quick references, etc.)
- Only modify the Topic Index tables to add the Key Files column
- Present a diff of the changes, not the full file

## Anti-Patterns

- **Don't guess Key Files without verification.** Every path must exist on disk.
- **Don't overwrite existing README.md content.** Add Key Files column to existing tables; don't restructure.
- **Don't list every file in a module.** 2-5 key files per doc is enough for `/upd-docs` matching.
