---
description: Configure pyproject.toml for uv — idempotent; adds ruff, optionally scopes it to target folders
---

Set up or update `pyproject.toml` for uv in the current project. Bootstraps from zero when needed, adds ruff (and optionally other dev tools) as dev dependencies, and optionally constrains ruff's scope via `[tool.ruff] include`.

**Idempotent.** Re-running without requesting changes must produce no file modifications.

**Do not run `uv sync`.** This command only edits `pyproject.toml` (and `uv.lock` as uv writes it). The user installs the venv themselves when ready.

---

## Phase 1 — Inspect

Do these in parallel:

- Read `pyproject.toml` if it exists
- `ls -d src tests 2>/dev/null` to see which common top-level dirs are present

Record:

- `has_pyproject`: bool
- `current_deps`: list from `[project].dependencies`
- `current_dev_deps`: list from `[dependency-groups].dev` (preferred) or `[tool.uv.dev-dependencies]`
- `current_ruff_include`: value of `[tool.ruff] include` if set, else `None`
- `layout_signals`: which of `src/`, `tests/` exist

## Phase 2 — Ask about target folders (stylish defaults)

Use **AskUserQuestion**. Build the options dynamically based on what you inspected:

1. **First option, recommended.** Pick the most likely scope given `layout_signals` and `current_ruff_include`:
   - If `current_ruff_include` is set, recommend **"Keep current: `<current_ruff_include>`"**
   - Else if both `src/` and `tests/` exist, recommend **"src, tests (auto-detected)"**
   - Else if `src/` exists, recommend **"src (auto-detected)"**
   - Else if `tests/` exists, recommend **"tests (auto-detected)"**
   - Else recommend **"Project root (no restriction)"**
   Add `(Recommended)` to the label.

2. **Other concrete alternatives** (include 1–2 of these that are NOT the recommendation):
   - "Project root (no restriction)"
   - "src only"
   - "src, tests"

3. Let the implicit "Other" option handle custom globs.

**Phrase the question** so the user knows they can pick a preset or type custom:

> "Which folders should ruff format/lint? Pick a preset, or choose Other to type custom globs."

Convert bare folder names to globs when calling the script: `src` → `src/**/*.py`, `tests` → `tests/**/*.py`. Treat anything containing `*`, `/`, or `.py` as already a glob and pass it through.

**Idempotency gate.** If the user picks "Keep current" (or the chosen set equals `current_ruff_include`), skip writing anything to `[tool.ruff].include` — see Phase 5.

## Phase 3 — Ask about dev tools (multi-select with defaults)

Use **AskUserQuestion** with `multiSelect: true`. Build options dynamically:

- **ruff** — always first, labeled `ruff (Recommended)`. Pre-select by default unless already in `current_dev_deps`.
- **mypy** — include if not already present; pre-select if the project has type hints in any `*.py` file (quick check: `grep -rlE "^(def|class).*->" --include='*.py' -m 1 .` — a single match is enough signal).
- **pytest** — include if not present; pre-select if `tests/` exists.
- **pytest-asyncio** — include if not present; pre-select if async tests exist (`grep -rlE "^async def test_" --include='*.py' -m 1 tests/`).

Skip options for deps already in `current_dev_deps`. If all four are already installed, skip this question entirely.

## Phase 4 — Bootstrap runtime deps (only if pyproject.toml is missing)

Only if `has_pyproject == false`:

1. Scan imports:
   ```bash
   grep -rhE "^(from|import) " --include="*.py" . 2>/dev/null \
     | awk '{print $2}' | cut -d. -f1 | sort -u
   ```

2. Filter stdlib modules (use your judgment — typical stdlib: `os`, `sys`, `json`, `typing`, `pathlib`, `datetime`, `re`, `asyncio`, `collections`, `itertools`, `functools`, `logging`, etc.).

3. Map common import names to PyPI packages:
   `cv2` → `opencv-python`, `PIL` → `pillow`, `yaml` → `pyyaml`, `sklearn` → `scikit-learn`, `bs4` → `beautifulsoup4`, `dotenv` → `python-dotenv`, `serial` → `pyserial`, `skimage` → `scikit-image`. Use your judgment for others.

4. Ask via **AskUserQuestion** (single-select):
   - **"Install all analyzed deps: `<comma-list>` (Recommended)"** — first
   - "Skip runtime deps (add them manually later)"
   - Let "Other" capture "install a subset" — the user will type it.

## Phase 5 — Execute (minimum necessary)

Build up the plan. If **no changes are needed** (all requested deps present, `[tool.ruff]` already matches target folders, pyproject.toml exists), print:

> ✓ Already configured — nothing to change.

and stop.

Otherwise, run exactly the steps needed:

### 5a. Script invocation

If pyproject.toml is missing OR there are new deps to add, call:

```bash
bash ~/.claude/scripts/uv-setup.sh [flags]
```

Flags:
- `--deps pkg1,pkg2` — runtime deps from Phase 4 (only on fresh setup)
- `--dev-deps ruff,mypy` — dev deps selected in Phase 3 (comma-separated; skip the flag if all are already present)
- `--include "src/**/*.py,tests/**/*.py"` — only on fresh setup where the user picked scope

The script:
- Runs `uv init --bare` only if pyproject.toml is missing
- Runs `uv add --no-sync` only for deps not already in pyproject.toml
- Appends `[tool.ruff]` only if absent

### 5b. Update existing [tool.ruff].include (script won't)

If pyproject.toml already has `[tool.ruff]` AND the user picked a different include value than `current_ruff_include`, edit pyproject.toml directly with the **Edit** tool:

- If the `include = [...]` line exists under `[tool.ruff]`, replace it.
- If `[tool.ruff]` exists without `include`, insert the line immediately after the `[tool.ruff]` header.
- Preserve all other ruff settings.

Do not touch any `[tool.ruff.*]` sub-tables.

## Phase 6 — Report

Show the user:

1. A one-line summary of what changed (deps added, include set to `<value>`, or "no changes").
2. The current `[tool.ruff]` block and `[dependency-groups].dev` (or the legacy equivalent), so they can verify.
3. Remind them to `uv sync` when they want to install into the venv — the command deliberately did not.

---

## UX rules (applied throughout)

- Every question uses **AskUserQuestion** so the user sees a clickable UI, not a prose prompt.
- The first option is the best guess for this project, suffixed `(Recommended)`.
- At least one concrete alternative is offered; custom input is always available via the auto-added "Other" option.
- Never assume an answer — ask even if you're confident.
- When nothing needs to change, **say so and stop** rather than re-running no-op commands.
