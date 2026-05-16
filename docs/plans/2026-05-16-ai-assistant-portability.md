# AI Assistant Portability — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the user's Claude Code skills/commands/helpers version-controlled in `evangelist` and convertible to Codex CLI, Copilot CLI, and Cursor.

**Architecture:** `conf/ai/claude/` holds the canonical Claude artifacts (symlinked back into `~/.claude`). A stdlib-only Python converter (`conf/ai/convert/`) projects them onto the other three tools. `evangelist install ai` runs in Mode 1 (convert + finalization prompt) or Mode 2 (delegation prompt; agent runs/repairs the converter).

**Tech Stack:** Python 3.12 stdlib only (no third-party deps — runs at install time on locked-down machines); `unittest` for tests; Bash for install wiring.

**Spec:** `docs/specs/2026-05-16-ai-assistant-portability-design.md`

---

## Execution status — 2026-05-16

- **Done:** Tasks 1, 3–12 — converter, adapters, CLI, prompt templates,
  `install.sh`, `control.sh` + `install.bash4` wiring, README, CLAUDE.md
  sync note. Per-tool selection (`--tool codex|copilot|cursor|all`, flag
  or prompt, persisted as `ai-tool`) added alongside `--mode`. 7 unit
  tests pass; `ruff` clean; shell files `bash -n` clean.
- **Task 2:** `conf/ai/claude/` is populated with the 6 portable
  artifacts; `conf/ai/.gitignore` whitelists only those (auth/state
  cannot be committed). Remaining action: run `evangelist install ai` to
  symlink them into `~/.claude` — this swaps the live session's
  `~/.claude`, so run it then restart Claude Code.
- The history was soft-reset to fold all of this into one commit; the
  commit messages above are per-task notes, not separate commits.

---

## File Structure

```
conf/ai/
  claude/                       canonical Claude artifacts (symlink target)
  convert/
    __init__.py
    common.py                   evangelist-root + path-rewrite helpers
    sources.py                  discover Claude artifacts -> dataclasses
    emit.py                     Conversion dataclass; write + manifest + prune
    convert.py                  CLI entry point
    adapters/
      __init__.py
      codex.py
      copilot.py
      cursor.py
    prompts/
      finalize.md.tmpl          Mode 1 prompt
      delegate.md.tmpl          Mode 2 prompt
    tests/
      __init__.py
      test_sources.py
      test_emit.py
      test_codex.py
      test_copilot.py
      test_cursor.py
  install.sh                    symlink + mode dispatch (called by control.sh)
  README.md
```

The converter is a package run as `python3 -m convert.convert` from `conf/ai/`. Tests run as `python3 -m unittest discover convert/tests` from `conf/ai/`.

---

## Task 1: Audit and prune `~/.claude` artifacts

Operational, interactive — not TDD. Decide what is worth carrying before anything moves.

**Files:** none yet (review only)

- [ ] **Step 1: List current artifacts**

Run:
```bash
ls -la ~/.claude/commands ~/.claude/skills ~/.claude/scripts
cat ~/.claude/CLAUDE.md | head -5
```
Expected: 4 commands (`code_checks.md`, `ensure_code_quality.md`, `git_commit.md`, `uv-setup.md`), 5 skills (`changelog`, `init-docs`, `refactor-code`, `socratic-learning`, `upd-docs`), 2 scripts (`check_guard_clauses.py`, `uv-setup.sh`), `statusline.sh`, `settings.json`.

- [ ] **Step 2: Present each artifact to the user for keep/drop**

For each command, skill, and script, show its first ~10 lines and ask the user: keep, drop, or needs-edit. Record the decisions. Do not delete anything yet — produce a written keep-list.

- [ ] **Step 3: Confirm the keep-list**

Echo the final keep-list back to the user and get explicit confirmation before Task 2 moves files.

No commit (nothing changed yet).

---

## Task 2: Scaffold `conf/ai/` and symlink the canonical artifacts

Operational. Moves the kept artifacts into the repo and symlinks them back.

**Files:**
- Create: `conf/ai/claude/` (populated by move)
- Create: `conf/ai/.gitignore`

- [ ] **Step 1: Create the directory skeleton**

Run:
```bash
cd "$EVANGELIST"
mkdir -p conf/ai/claude conf/ai/convert/adapters conf/ai/convert/prompts conf/ai/convert/tests
```

- [ ] **Step 2: Move kept artifacts into the repo**

For each artifact on the Task 1 keep-list, move it from `~/.claude` into `conf/ai/claude/`, preserving the relative layout:
```bash
mv ~/.claude/commands   conf/ai/claude/commands
mv ~/.claude/skills     conf/ai/claude/skills
mv ~/.claude/scripts    conf/ai/claude/scripts
mv ~/.claude/CLAUDE.md  conf/ai/claude/CLAUDE.md
mv ~/.claude/statusline.sh conf/ai/claude/statusline.sh
mv ~/.claude/settings.json conf/ai/claude/settings.json
```
(Skip any artifact the user chose to drop.)

- [ ] **Step 3: Symlink them back into `~/.claude`**

```bash
for item in commands skills scripts CLAUDE.md statusline.sh settings.json; do
  ln -sfn "$EVANGELIST/conf/ai/claude/$item" "$HOME/.claude/$item"
done
ls -la ~/.claude | grep -- '->'
```
Expected: each of the six entries shown as a symlink into `conf/ai/claude/`.

- [ ] **Step 4: Add `.gitignore` for generated/cache artifacts**

Create `conf/ai/.gitignore`:
```
convert/**/__pycache__/
convert/tests/.pytest_cache/
```

- [ ] **Step 5: Commit**

```bash
cd "$EVANGELIST"
git add conf/ai
git commit -m "Add conf/ai: canonical Claude Code artifacts

+ Move ~/.claude commands, skills, scripts, CLAUDE.md, statusline,
  settings into conf/ai/claude/ under version control
+ Symlink them back into ~/.claude so edits stay in sync"
```

---

## Task 3: `convert/common.py` and `convert/sources.py`

**Files:**
- Create: `conf/ai/convert/__init__.py`
- Create: `conf/ai/convert/common.py`
- Create: `conf/ai/convert/sources.py`
- Test: `conf/ai/convert/tests/__init__.py`, `conf/ai/convert/tests/test_sources.py`

- [ ] **Step 1: Write the failing test**

Create `conf/ai/convert/tests/__init__.py` (empty) and `conf/ai/convert/tests/test_sources.py`:
```python
import tempfile
import unittest
from pathlib import Path

from convert.sources import discover


class TestDiscover(unittest.TestCase):
    def _build(self, root: Path) -> None:
        claude = root / "claude"
        (claude / "skills" / "demo").mkdir(parents=True)
        (claude / "skills" / "demo" / "SKILL.md").write_text(
            "---\nname: demo\ndescription: a demo\n---\nbody\n"
        )
        (claude / "commands").mkdir()
        (claude / "commands" / "do_it.md").write_text(
            "---\ndescription: does it\n---\nthe command body\n"
        )
        (claude / "commands" / "bare.md").write_text("just a body line\n")
        (claude / "scripts").mkdir()
        (claude / "CLAUDE.md").write_text("global instructions\n")

    def test_discovers_all_artifact_kinds(self):
        with tempfile.TemporaryDirectory() as tmp:
            claude = Path(tmp) / "claude"
            self._build(Path(tmp))
            src = discover(claude)

        self.assertEqual([s.name for s in src.skills], ["demo"])
        self.assertEqual(sorted(c.name for c in src.commands), ["bare", "do_it"])
        do_it = next(c for c in src.commands if c.name == "do_it")
        self.assertEqual(do_it.frontmatter["description"], "does it")
        self.assertEqual(do_it.body, "the command body\n")
        bare = next(c for c in src.commands if c.name == "bare")
        self.assertEqual(bare.frontmatter, {})
        self.assertEqual(bare.body, "just a body line\n")
        self.assertIsNotNone(src.instructions)
        self.assertIsNotNone(src.scripts_dir)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd "$EVANGELIST/conf/ai" && python3 -m unittest discover convert/tests -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'convert.sources'`.

- [ ] **Step 3: Write `common.py`**

Create `conf/ai/convert/__init__.py` (empty) and `conf/ai/convert/common.py`:
```python
"""Shared helpers for the converter."""

from pathlib import Path


def evangelist_root() -> Path:
    """The evangelist repo root, derived from this file's location:
    .../evangelist/conf/ai/convert/common.py -> parents[3]."""
    return Path(__file__).resolve().parents[3]


def claude_dir() -> Path:
    return evangelist_root() / "conf" / "ai" / "claude"


def slug(name: str) -> str:
    """Lowercase-hyphenated form — required for Copilot skill names,
    safe for the others."""
    return name.strip().lower().replace("_", "-").replace(" ", "-")


def rewrite_script_paths(text: str) -> str:
    """Repoint `~/.claude/scripts/...` references at the canonical
    scripts directory, so converted artifacts never depend on a
    Claude-only path."""
    canonical = claude_dir() / "scripts"
    return text.replace("~/.claude/scripts", str(canonical))
```

- [ ] **Step 4: Write `sources.py`**

Create `conf/ai/convert/sources.py`:
```python
"""Discover Claude Code artifacts in the canonical source tree."""

import re
from dataclasses import dataclass
from pathlib import Path

_FRONTMATTER = re.compile(r"\A---\n(.*?)\n---\n(.*)\Z", re.DOTALL)


@dataclass
class Skill:
    name: str
    directory: Path


@dataclass
class Command:
    name: str
    frontmatter: dict[str, str]
    body: str


@dataclass
class Sources:
    skills: list[Skill]
    commands: list[Command]
    instructions: Path | None
    scripts_dir: Path | None


def _split_frontmatter(text: str) -> tuple[dict[str, str], str]:
    """Return (frontmatter, body). Frontmatter parsing is intentionally
    minimal — flat `key: value` pairs, which is all command files use."""
    match = _FRONTMATTER.match(text)
    if not match:
        return {}, text

    meta: dict[str, str] = {}
    for line in match.group(1).splitlines():
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        meta[key.strip()] = value.strip()

    return meta, match.group(2)


def discover(claude_dir: Path) -> Sources:
    skills: list[Skill] = []
    skills_root = claude_dir / "skills"
    if skills_root.is_dir():
        for entry in sorted(skills_root.iterdir()):
            if (entry / "SKILL.md").is_file():
                skills.append(Skill(name=entry.name, directory=entry))

    commands: list[Command] = []
    commands_root = claude_dir / "commands"
    if commands_root.is_dir():
        for entry in sorted(commands_root.glob("*.md")):
            meta, body = _split_frontmatter(entry.read_text())
            commands.append(Command(name=entry.stem, frontmatter=meta, body=body))

    instructions = claude_dir / "CLAUDE.md"
    scripts_dir = claude_dir / "scripts"

    return Sources(
        skills=skills,
        commands=commands,
        instructions=instructions if instructions.is_file() else None,
        scripts_dir=scripts_dir if scripts_dir.is_dir() else None,
    )
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd "$EVANGELIST/conf/ai" && python3 -m unittest discover convert/tests -v`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
cd "$EVANGELIST"
git add conf/ai/convert
git commit -m "Add converter source discovery

+ common.py: evangelist-root, slug, script-path rewrite helpers
+ sources.py: discover skills/commands/instructions into dataclasses"
```

---

## Task 4: `convert/emit.py`

**Files:**
- Create: `conf/ai/convert/emit.py`
- Test: `conf/ai/convert/tests/test_emit.py`

- [ ] **Step 1: Write the failing test**

Create `conf/ai/convert/tests/test_emit.py`:
```python
import tempfile
import unittest
from pathlib import Path

from convert.emit import Conversion, emit, read_manifest


class TestEmit(unittest.TestCase):
    def test_writes_files_and_manifest(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            conv = Conversion(tool="codex", tool_root=root / "cfg")
            conv.files[root / "out" / "a.md"] = "alpha"
            emit(conv, dry_run=False)

            self.assertEqual((root / "out" / "a.md").read_text(), "alpha")
            self.assertEqual(read_manifest(root / "cfg"), [root / "out" / "a.md"])

    def test_prunes_files_dropped_since_last_run(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            first = Conversion(tool="codex", tool_root=root / "cfg")
            first.files[root / "out" / "old.md"] = "x"
            emit(first, dry_run=False)

            second = Conversion(tool="codex", tool_root=root / "cfg")
            second.files[root / "out" / "new.md"] = "y"
            emit(second, dry_run=False)

            self.assertFalse((root / "out" / "old.md").exists())
            self.assertTrue((root / "out" / "new.md").exists())

    def test_dry_run_writes_nothing(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            conv = Conversion(tool="codex", tool_root=root / "cfg")
            conv.files[root / "out" / "a.md"] = "alpha"
            emit(conv, dry_run=True)

            self.assertFalse((root / "out" / "a.md").exists())


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd "$EVANGELIST/conf/ai" && python3 -m unittest convert.tests.test_emit -v`
Expected: FAIL — `No module named 'convert.emit'`.

- [ ] **Step 3: Write `emit.py`**

Create `conf/ai/convert/emit.py`:
```python
"""Write a tool's generated outputs and maintain a prune manifest."""

import shutil
from dataclasses import dataclass, field
from pathlib import Path

_MANIFEST_NAME = ".convert-manifest"


@dataclass
class Conversion:
    """One tool's full set of generated outputs.

    `files` maps an absolute destination path to its content.
    `trees` maps an absolute destination directory to a source
    directory copied wholesale (used for skill folders).
    `notes` are messages surfaced to the agent prompt.
    """
    tool: str
    tool_root: Path
    files: dict[Path, str] = field(default_factory=dict)
    trees: dict[Path, Path] = field(default_factory=dict)
    notes: list[str] = field(default_factory=list)


def _manifest(tool_root: Path) -> Path:
    return tool_root / _MANIFEST_NAME


def read_manifest(tool_root: Path) -> list[Path]:
    path = _manifest(tool_root)
    if not path.is_file():
        return []

    return [Path(p) for p in path.read_text().splitlines() if p.strip()]


def emit(conv: Conversion, dry_run: bool) -> None:
    targets = sorted(set(conv.files) | set(conv.trees))

    if dry_run:
        for path in targets:
            print(f"  [{conv.tool}] would write {path}")
        return

    previous = set(read_manifest(conv.tool_root))

    # Trees first, then files: a files[] entry for <skill>/SKILL.md
    # then overrides the copied-in copy with a path-rewritten version.
    for dst, src in conv.trees.items():
        if dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(src, dst)

    for dst, content in conv.files.items():
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_text(content)

    for stale in sorted(previous - set(targets)):
        if stale.is_dir():
            shutil.rmtree(stale, ignore_errors=True)
        else:
            stale.unlink(missing_ok=True)

    conv.tool_root.mkdir(parents=True, exist_ok=True)
    _manifest(conv.tool_root).write_text("\n".join(str(p) for p in targets) + "\n")
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd "$EVANGELIST/conf/ai" && python3 -m unittest convert.tests.test_emit -v`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
cd "$EVANGELIST"
git add conf/ai/convert/emit.py conf/ai/convert/tests/test_emit.py
git commit -m "Add converter emit layer

+ Conversion dataclass; emit() writes files/trees, prunes stale
  outputs via a per-tool .convert-manifest, supports --dry-run"
```

---

## Task 5: `convert/adapters/codex.py`

**Files:**
- Create: `conf/ai/convert/adapters/__init__.py`
- Create: `conf/ai/convert/adapters/codex.py`
- Test: `conf/ai/convert/tests/test_codex.py`

- [ ] **Step 1: Write the failing test**

Create `conf/ai/convert/tests/test_codex.py`:
```python
import tempfile
import unittest
from pathlib import Path

from convert.adapters import codex
from convert.sources import Command, Skill, Sources


def _sources(root: Path) -> Sources:
    skill_dir = root / "claude" / "skills" / "demo"
    skill_dir.mkdir(parents=True)
    (skill_dir / "SKILL.md").write_text("---\nname: demo\ndescription: d\n---\nb\n")
    instructions = root / "claude" / "CLAUDE.md"
    instructions.write_text("global\n")
    return Sources(
        skills=[Skill(name="demo", directory=skill_dir)],
        commands=[Command(name="ensure_code_quality",
                          frontmatter={"description": "QA pass"}, body="do qa\n")],
        instructions=instructions,
        scripts_dir=None,
    )


class TestCodexAdapter(unittest.TestCase):
    def test_skill_command_and_instructions_targets(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            home = root / "home"
            conv = codex.convert(_sources(root), home)

        self.assertEqual(conv.tool, "codex")
        self.assertIn(home / ".agents" / "skills" / "demo", conv.trees)
        # command is wrapped as a slugified skill
        skill_md = home / ".agents" / "skills" / "ensure-code-quality" / "SKILL.md"
        self.assertIn(skill_md, conv.files)
        self.assertIn("name: ensure-code-quality", conv.files[skill_md])
        self.assertIn("description: QA pass", conv.files[skill_md])
        self.assertIn("do qa", conv.files[skill_md])
        self.assertIn(home / ".codex" / "AGENTS.md", conv.files)
        self.assertTrue(conv.notes)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd "$EVANGELIST/conf/ai" && python3 -m unittest convert.tests.test_codex -v`
Expected: FAIL — `No module named 'convert.adapters.codex'`.

- [ ] **Step 3: Write `codex.py`**

Create `conf/ai/convert/adapters/__init__.py` (empty) and `conf/ai/convert/adapters/codex.py`:
```python
"""Adapter: Claude Code artifacts -> OpenAI Codex CLI."""

from pathlib import Path

from convert.common import rewrite_script_paths, slug
from convert.emit import Conversion
from convert.sources import Command, Sources


def _command_skill_body(cmd: Command) -> str:
    description = cmd.frontmatter.get("description") or next(
        (ln.strip() for ln in cmd.body.splitlines() if ln.strip()), cmd.name
    )
    body = rewrite_script_paths(cmd.body)
    return f"---\nname: {slug(cmd.name)}\ndescription: {description}\n---\n{body}"


def convert(sources: Sources, home: Path) -> Conversion:
    conv = Conversion(tool="codex", tool_root=home / ".codex")
    skills_dir = home / ".agents" / "skills"

    for skill in sources.skills:
        dst = skills_dir / skill.name
        conv.trees[dst] = skill.directory
        skill_md = (skill.directory / "SKILL.md").read_text()
        conv.files[dst / "SKILL.md"] = rewrite_script_paths(skill_md)

    for cmd in sources.commands:
        conv.files[skills_dir / slug(cmd.name) / "SKILL.md"] = _command_skill_body(cmd)

    if sources.instructions:
        conv.files[home / ".codex" / "AGENTS.md"] = sources.instructions.read_text()

    conv.notes.append(
        "MCP servers are not converted — configure them in "
        "~/.codex/config.toml under [mcp_servers.<name>]."
    )
    return conv
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd "$EVANGELIST/conf/ai" && python3 -m unittest convert.tests.test_codex -v`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd "$EVANGELIST"
git add conf/ai/convert/adapters
git commit -m "Add Codex adapter

+ Skills copied to ~/.agents/skills/; commands wrapped as skills;
  CLAUDE.md -> ~/.codex/AGENTS.md; MCP left to the agent prompt"
```

---

## Task 6: `convert/adapters/copilot.py`

**Files:**
- Create: `conf/ai/convert/adapters/copilot.py`
- Test: `conf/ai/convert/tests/test_copilot.py`

- [ ] **Step 1: Write the failing test**

Create `conf/ai/convert/tests/test_copilot.py`:
```python
import tempfile
import unittest
from pathlib import Path

from convert.adapters import copilot
from convert.sources import Command, Skill, Sources


def _sources(root: Path) -> Sources:
    skill_dir = root / "claude" / "skills" / "init-docs"
    skill_dir.mkdir(parents=True)
    (skill_dir / "SKILL.md").write_text("---\nname: init-docs\ndescription: d\n---\nb\n")
    instructions = root / "claude" / "CLAUDE.md"
    instructions.write_text("global\n")
    return Sources(
        skills=[Skill(name="init-docs", directory=skill_dir)],
        commands=[Command(name="git_commit", frontmatter={}, body="compose a commit\n")],
        instructions=instructions,
        scripts_dir=None,
    )


class TestCopilotAdapter(unittest.TestCase):
    def test_targets(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            home = root / "home"
            conv = copilot.convert(_sources(root), home)

        self.assertEqual(conv.tool, "copilot")
        self.assertIn(home / ".copilot" / "skills" / "init-docs", conv.trees)
        skill_md = home / ".copilot" / "skills" / "git-commit" / "SKILL.md"
        self.assertIn(skill_md, conv.files)
        self.assertIn("name: git-commit", conv.files[skill_md])
        self.assertIn(home / ".copilot" / "copilot-instructions.md", conv.files)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd "$EVANGELIST/conf/ai" && python3 -m unittest convert.tests.test_copilot -v`
Expected: FAIL — `No module named 'convert.adapters.copilot'`.

- [ ] **Step 3: Write `copilot.py`**

Create `conf/ai/convert/adapters/copilot.py`:
```python
"""Adapter: Claude Code artifacts -> GitHub Copilot CLI."""

from pathlib import Path

from convert.common import rewrite_script_paths, slug
from convert.emit import Conversion
from convert.sources import Command, Sources


def _command_skill_body(cmd: Command) -> str:
    description = cmd.frontmatter.get("description") or next(
        (ln.strip() for ln in cmd.body.splitlines() if ln.strip()), cmd.name
    )
    body = rewrite_script_paths(cmd.body)
    return f"---\nname: {slug(cmd.name)}\ndescription: {description}\n---\n{body}"


def convert(sources: Sources, home: Path) -> Conversion:
    conv = Conversion(tool="copilot", tool_root=home / ".copilot")
    skills_dir = home / ".copilot" / "skills"

    for skill in sources.skills:
        dst = skills_dir / skill.name
        conv.trees[dst] = skill.directory
        skill_md = (skill.directory / "SKILL.md").read_text()
        conv.files[dst / "SKILL.md"] = rewrite_script_paths(skill_md)

    for cmd in sources.commands:
        conv.files[skills_dir / slug(cmd.name) / "SKILL.md"] = _command_skill_body(cmd)

    if sources.instructions:
        target = home / ".copilot" / "copilot-instructions.md"
        conv.files[target] = sources.instructions.read_text()

    conv.notes.append(
        "MCP servers are not converted — configure them in "
        "~/.copilot/mcp-config.json (verify the exact schema key)."
    )
    return conv
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd "$EVANGELIST/conf/ai" && python3 -m unittest convert.tests.test_copilot -v`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd "$EVANGELIST"
git add conf/ai/convert/adapters/copilot.py conf/ai/convert/tests/test_copilot.py
git commit -m "Add Copilot CLI adapter

+ Skills -> ~/.copilot/skills/; commands wrapped as skills;
  CLAUDE.md -> ~/.copilot/copilot-instructions.md"
```

---

## Task 7: `convert/adapters/cursor.py`

**Files:**
- Create: `conf/ai/convert/adapters/cursor.py`
- Test: `conf/ai/convert/tests/test_cursor.py`

- [ ] **Step 1: Write the failing test**

Create `conf/ai/convert/tests/test_cursor.py`:
```python
import tempfile
import unittest
from pathlib import Path

from convert.adapters import cursor
from convert.sources import Command, Skill, Sources


def _sources(root: Path) -> Sources:
    skill_dir = root / "claude" / "skills" / "changelog"
    skill_dir.mkdir(parents=True)
    (skill_dir / "SKILL.md").write_text("---\nname: changelog\ndescription: d\n---\nb\n")
    instructions = root / "claude" / "CLAUDE.md"
    instructions.write_text("global\n")
    return Sources(
        skills=[Skill(name="changelog", directory=skill_dir)],
        commands=[Command(name="code_checks",
                          frontmatter={"description": "lint"}, body="run ruff\n")],
        instructions=instructions,
        scripts_dir=None,
    )


class TestCursorAdapter(unittest.TestCase):
    def test_commands_are_native_skills_are_copied(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            home = root / "home"
            conv = cursor.convert(_sources(root), home)

        self.assertEqual(conv.tool, "cursor")
        self.assertIn(home / ".cursor" / "skills" / "changelog", conv.trees)
        # Cursor commands are plain markdown, filename == command name,
        # no frontmatter.
        cmd_file = home / ".cursor" / "commands" / "code_checks.md"
        self.assertIn(cmd_file, conv.files)
        self.assertEqual(conv.files[cmd_file], "run ruff\n")
        # no global instructions file for Cursor
        self.assertNotIn(home / ".cursor" / "AGENTS.md", conv.files)
        self.assertTrue(conv.notes)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd "$EVANGELIST/conf/ai" && python3 -m unittest convert.tests.test_cursor -v`
Expected: FAIL — `No module named 'convert.adapters.cursor'`.

- [ ] **Step 3: Write `cursor.py`**

Create `conf/ai/convert/adapters/cursor.py`:
```python
"""Adapter: Claude Code artifacts -> Cursor."""

from pathlib import Path

from convert.common import rewrite_script_paths
from convert.emit import Conversion
from convert.sources import Sources


def convert(sources: Sources, home: Path) -> Conversion:
    conv = Conversion(tool="cursor", tool_root=home / ".cursor")

    skills_dir = home / ".cursor" / "skills"
    for skill in sources.skills:
        dst = skills_dir / skill.name
        conv.trees[dst] = skill.directory
        skill_md = (skill.directory / "SKILL.md").read_text()
        conv.files[dst / "SKILL.md"] = rewrite_script_paths(skill_md)

    # Cursor commands are plain markdown — no frontmatter; the filename
    # becomes the command name.
    commands_dir = home / ".cursor" / "commands"
    for cmd in sources.commands:
        conv.files[commands_dir / f"{cmd.name}.md"] = rewrite_script_paths(cmd.body)

    conv.notes.append(
        "Cursor has no global instructions file (user rules are UI-only) "
        "— CLAUDE.md was not converted; paste its contents into "
        "Cursor Settings > Rules, or add an AGENTS.md per project."
    )
    conv.notes.append(
        "Cursor's global skills path (~/.cursor/skills/) is unconfirmed "
        "— verify Cursor reads it, or place skills per-project under "
        ".cursor/skills/."
    )
    return conv
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd "$EVANGELIST/conf/ai" && python3 -m unittest convert.tests.test_cursor -v`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd "$EVANGELIST"
git add conf/ai/convert/adapters/cursor.py conf/ai/convert/tests/test_cursor.py
git commit -m "Add Cursor adapter

+ Skills -> ~/.cursor/skills/; commands -> native ~/.cursor/commands/
  (frontmatter stripped); notes flag the global-rules/skills caveats"
```

---

## Task 8: `convert/convert.py` CLI entry point

**Files:**
- Create: `conf/ai/convert/convert.py`

- [ ] **Step 1: Write `convert.py`**

Create `conf/ai/convert/convert.py`:
```python
#!/usr/bin/env python3
"""Convert Claude Code artifacts to Codex / Copilot / Cursor formats.

Stdlib only — runs at install time with no third-party dependencies.
"""

import argparse
from pathlib import Path

from convert.adapters import codex, copilot, cursor
from convert.common import claude_dir
from convert.emit import emit
from convert.sources import discover

_ADAPTERS = {
    "codex": codex.convert,
    "copilot": copilot.convert,
    "cursor": cursor.convert,
}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--tool", choices=sorted(_ADAPTERS), help="convert one tool only"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="print planned writes, change nothing"
    )
    args = parser.parse_args()

    sources = discover(claude_dir())
    home = Path.home()
    tools = [args.tool] if args.tool else sorted(_ADAPTERS)

    for tool in tools:
        conv = _ADAPTERS[tool](sources, home)
        print(f"[{tool}] {len(conv.files)} files, {len(conv.trees)} skill trees")
        emit(conv, args.dry_run)
        for note in conv.notes:
            print(f"  note: {note}")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Smoke-test the CLI with `--dry-run`**

Run: `cd "$EVANGELIST/conf/ai" && python3 -m convert.convert --dry-run`
Expected: for each of codex/copilot/cursor, a count line, `would write …` lines pointing at real `~/.agents`, `~/.copilot`, `~/.cursor` paths, and the note lines. No files created — verify with `ls ~/.agents ~/.copilot 2>/dev/null` (should not exist yet).

- [ ] **Step 3: Run the full test suite**

Run: `cd "$EVANGELIST/conf/ai" && python3 -m unittest discover convert/tests -v`
Expected: PASS — all tests from Tasks 3–7.

- [ ] **Step 4: Commit**

```bash
cd "$EVANGELIST"
git add conf/ai/convert/convert.py
git commit -m "Add converter CLI entry point

+ convert.py: --tool / --dry-run; dispatches the three adapters"
```

---

## Task 9: Mode 1 / Mode 2 prompt templates

**Files:**
- Create: `conf/ai/convert/prompts/finalize.md.tmpl`
- Create: `conf/ai/convert/prompts/delegate.md.tmpl`

- [ ] **Step 1: Write `finalize.md.tmpl`**

Create `conf/ai/convert/prompts/finalize.md.tmpl` (`@TOOL@` and `@CLAUDE_SRC@` are substituted by `install.sh`):
```markdown
# Finalize the migrated config for @TOOL@

A deterministic converter has just generated @TOOL@ configuration from
the canonical Claude Code artifacts at `@CLAUDE_SRC@`.

Your job — review and correct that generated output:

1. Compare each generated skill/command/instructions file against its
   source under `@CLAUDE_SRC@`. Fix anything that did not translate:
   frontmatter keys, file placement, broken references.
2. Confirm helper-script paths in the generated files resolve to real
   files (they should point into `@CLAUDE_SRC@/scripts/`).
3. Set up MCP servers — the converter intentionally skips these.
   Configure them in @TOOL@'s MCP config in @TOOL@'s native format.
4. Report what you changed and anything you could not resolve.

Do not edit files under `@CLAUDE_SRC@` — that is the Claude Code source
of truth.
```

- [ ] **Step 2: Write `delegate.md.tmpl`**

Create `conf/ai/convert/prompts/delegate.md.tmpl` (`@TOOL@`, `@CLAUDE_SRC@`, `@AI_DIR@` are substituted):
```markdown
# Migrate the Claude Code config to @TOOL@

The canonical Claude Code artifacts are at `@CLAUDE_SRC@` (skills,
commands, helper scripts, CLAUDE.md). A deterministic converter exists
at `@AI_DIR@/convert/` with a per-tool adapter
`@AI_DIR@/convert/adapters/@TOOL@.py`.

Your job:

1. Read the @TOOL@ adapter and judge whether it is correct and current
   against @TOOL@'s present-day config format and paths.
2. If it is sound, run it: `cd @AI_DIR@ && python3 -m convert.convert
   --tool @TOOL@`.
3. If it is stale or wrong, **patch the adapter in place**
   (`@AI_DIR@/convert/adapters/@TOOL@.py`) so it is correct, then run
   it. The repair persists for every future run, including Mode 1.
   Leave the edits in the working tree for the user to review and
   commit — do not commit them yourself.
4. Set up MCP servers for @TOOL@ from any MCP config the user points
   you at; the converter does not handle MCP.
5. Verify the result and report what you ran, patched, and set up.

Do not edit files under `@CLAUDE_SRC@` — that is the Claude Code source
of truth.
```

- [ ] **Step 3: Commit**

```bash
cd "$EVANGELIST"
git add conf/ai/convert/prompts
git commit -m "Add Mode 1 / Mode 2 migration prompt templates

+ finalize.md.tmpl: agent QAs the deterministic conversion
+ delegate.md.tmpl: agent runs/repairs the converter (self-healing)"
```

---

## Task 10: `conf/ai/install.sh`

**Files:**
- Create: `conf/ai/install.sh`

- [ ] **Step 1: Write `install.sh`**

Create `conf/ai/install.sh`:
```bash
#!/usr/bin/env bash
## conf/ai/install.sh — provision Claude Code config and convert it to
## the other assistants. Invoked by evangelist's `ai` component.
## Usage: install.sh [MODE]   (MODE = 1 scripted+finalize, 2 delegate)

set -euo pipefail

AI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SRC="$AI_DIR/claude"
MODE="${1:-1}"

## --- symlink the canonical Claude artifacts into ~/.claude ---
mkdir -p "$HOME/.claude"
for item in commands skills scripts CLAUDE.md statusline.sh settings.json; do
  src="$CLAUDE_SRC/$item"
  dst="$HOME/.claude/$item"
  [[ -e "$src" ]] || continue
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    mv "$dst" "$dst.pre-evangelist.bak"
  fi
  ln -sfn "$src" "$dst"
done
echo "Linked Claude Code artifacts into ~/.claude"

## --- other-tool conversion ---
PROMPT_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/evangelist/ai-migration"
mkdir -p "$PROMPT_DIR"

render() {
  ## render <template> <out> — substitute the @VAR@ placeholders
  sed -e "s|@TOOL@|$1|g" -e "s|@CLAUDE_SRC@|$CLAUDE_SRC|g" \
      -e "s|@AI_DIR@|$AI_DIR|g" "$2" >"$3"
}

if [[ "$MODE" == "1" ]]; then
  ( cd "$AI_DIR" && python3 -m convert.convert )
  for tool in codex copilot cursor; do
    render "$tool" "$AI_DIR/convert/prompts/finalize.md.tmpl" \
      "$PROMPT_DIR/$tool-FINALIZE.md"
  done
  echo "Mode 1: converted. Review prompts in $PROMPT_DIR/"
else
  for tool in codex copilot cursor; do
    render "$tool" "$AI_DIR/convert/prompts/delegate.md.tmpl" \
      "$PROMPT_DIR/$tool-DELEGATE.md"
  done
  echo "Mode 2: open each target assistant and run the prompt in $PROMPT_DIR/"
fi
```

- [ ] **Step 2: Make it executable and smoke-test Mode 2**

Run:
```bash
chmod +x "$EVANGELIST/conf/ai/install.sh"
"$EVANGELIST/conf/ai/install.sh" 2
ls "${XDG_CACHE_HOME:-$HOME/.cache}/evangelist/ai-migration"
```
Expected: symlink line, `Mode 2:` line, and three `*-DELEGATE.md` files listed. Open one and confirm the `@`-placeholders are all substituted.

- [ ] **Step 3: Smoke-test Mode 1**

Run: `"$EVANGELIST/conf/ai/install.sh" 1`
Expected: converter count/note lines, then `Mode 1: converted`, and three `*-FINALIZE.md` files in the prompt dir. Verify `~/.agents/skills/`, `~/.copilot/skills/`, `~/.cursor/commands/` now exist and contain the converted artifacts.

- [ ] **Step 4: Commit**

```bash
cd "$EVANGELIST"
git add conf/ai/install.sh
git commit -m "Add conf/ai install script

+ Symlink Claude artifacts into ~/.claude (back up non-symlink files)
+ Mode 1: run converter + render finalization prompts
+ Mode 2: render delegation prompts"
```

---

## Task 11: Wire the `ai` component into evangelist

> Implemented with an added `--tool codex|copilot|cursor|all` selector
> (flag or interactive prompt, persisted as `ai-tool`) parallel to
> `--mode`; `install.sh` takes `MODE` and `TOOL` positional args.

**Files:**
- Modify: `_impl/control.sh`
- Modify: `_impl/install.bash4` (and `_impl/install.bash3` if old-bash support is kept)

- [ ] **Step 1: Confirm the dispatch points**

In `_impl/control.sh`: `control::install` parses flags then loops `for _ARG in "$@"` with a `case` calling `install::<component>_settings` (lines ~191-208); `control::update` re-applies on changed paths; `control::uninstall` reverses installs. In `_impl/install.bash4`: `install::check_arguments` validates allowed component names, and each `install::<component>_settings` does the work. The `ai` component is added to both files.

- [ ] **Step 2: Parse and strip the `--mode` flag in `control::install`**

`control::install` munges component arguments (dedup, `bash+` expansion), so `--mode` must be extracted first — exactly as `--clean` is. Immediately after the `--clean` block (after its `fi`, near line 120 of `control.sh`), add:
```bash
  ## Extract --mode (used only by the `ai` component) before the
  ## component-argument munging below can swallow it. Mirrors --clean.
  _AI_MODE=""
  local -a _rest=()
  while [[ $# -gt 0 ]]; do
    case $1 in
    --mode) _AI_MODE="${2:-}"; shift 2 ;;
    --mode=*) _AI_MODE="${1#*=}"; shift ;;
    *) _rest+=("$1"); shift ;;
    esac
  done
  set -- "${_rest[@]}"
```
`_AI_MODE` has no `local` keyword, so (per control.sh's scoping note) it is visible to `install::ai_settings` called later in the loop.

- [ ] **Step 3: Allow `ai` and dispatch it**

In `_impl/install.bash4`, add `ai` to the allowed-component list inside `install::check_arguments` (match the existing list's exact form). In `control.sh`'s component `case` (lines ~191-205), add a branch alongside `kitty)`:
```bash
    ai) install::ai_settings ;;
```

- [ ] **Step 4: Add `install::ai_settings` to `install.bash4`**

Add this function next to the other `install::*_settings` functions in `_impl/install.bash4`:
```bash
install::ai_settings() {
  local mode="$_AI_MODE"
  if [[ -z $mode ]]; then
    local msg
    msg='Choose the AI-assistant migration approach:\n'
    msg+='  1) Scripted — run the converter now, then emit per-tool\n'
    msg+='     finalization prompts for the target assistant to QA.\n'
    msg+='  2) Agent-driven — emit per-tool delegation prompts; the\n'
    msg+='     target assistant runs and self-heals the converter.\n'
    NOTE 210 "$msg"
    read -p '(1|2): ' mode
  fi
  [[ $mode =~ ^[12]$ ]] || {
    ECHO2 "Invalid --mode: '$mode' (expected 1 or 2)"
    return 1
  }

  local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/evangelist"
  mkdir -p "$state_dir"
  echo "$mode" >"$state_dir/ai-mode"

  bash "$EVANGELIST/conf/ai/install.sh" "$mode"
}
```
A `--mode` flag makes it non-interactive; with no flag the user is prompted. The chosen mode is persisted to `$XDG_STATE_HOME/evangelist/ai-mode` for `update` to reuse.

- [ ] **Step 5: Re-run on update in `control::update`**

After the `systemd` re-apply block in `control::update` (near line 334 of `control.sh`), add:
```bash
  if grep -qE '^conf/ai/' <<<"$UPD" && grep -q '^ai' .update-list; then
    local ai_mode
    ai_mode=$(cat "${XDG_STATE_HOME:-$HOME/.local/state}/evangelist/ai-mode" \
      2>/dev/null || echo 1)
    bash "$EVANGELIST/conf/ai/install.sh" "$ai_mode"
  fi
```

- [ ] **Step 6: Reverse it in `control::uninstall`**

In `control::uninstall`, before the `.bak` restore loop (near line 492 of `control.sh`), add:
```bash
  if grep -q '^ai' .update-list; then
    local item tool manifest f
    for item in commands skills scripts CLAUDE.md statusline.sh settings.json; do
      [[ -L "$HOME/.claude/$item" ]] && rm -f "$HOME/.claude/$item"
      [[ -e "$HOME/.claude/$item.pre-evangelist.bak" ]] &&
        mv "$HOME/.claude/$item.pre-evangelist.bak" "$HOME/.claude/$item"
    done
    for tool in codex copilot cursor; do
      manifest="$HOME/.$tool/.convert-manifest"
      [[ -f "$manifest" ]] || continue
      while IFS= read -r f; do
        [[ -n "$f" ]] || continue
        [[ -d "$f" ]] && rm -rf "$f" || rm -f "$f"
      done <"$manifest"
      rm -f "$manifest"
    done
  fi
```

- [ ] **Step 7: Verify the wiring**

Run (non-interactive, Mode 2 — emits prompts only):
```bash
cd "$EVANGELIST" && bash evangelist.sh install ai --mode 2
```
Expected: symlink line, `Mode 2:` line, three `*-DELEGATE.md` files in
`$XDG_CACHE_HOME/evangelist/ai-migration/`. Then run `bash evangelist.sh
install ai` with no flag and confirm the `(1|2):` prompt appears.

- [ ] **Step 8: Commit**

```bash
cd "$EVANGELIST"
git add _impl/control.sh _impl/install.bash4
git commit -m "Wire the ai component into evangelist control

+ install ai [--mode 1|2]: --mode flag is non-interactive, no flag
  prompts; mode persisted under XDG_STATE_HOME
+ update ai re-runs the converter on conf/ai changes
+ uninstall ai unlinks ~/.claude and prunes generated tool outputs"
```

---

## Task 12: Converter-refresh note and `conf/ai/README.md`

**Files:**
- Modify: `conf/ai/claude/CLAUDE.md`
- Create: `conf/ai/README.md`

- [ ] **Step 1: Add the refresh note to `CLAUDE.md`**

Append this section to `conf/ai/claude/CLAUDE.md` (which is symlinked as `~/.claude/CLAUDE.md`):
```markdown
## AI assistant config sync

Skills, commands, and helper scripts in `~/.claude` are version-controlled
in `$EVANGELIST/conf/ai/claude/` (symlinked — edits are already saved
there). After changing any of them, run `evangelist update ai` to refresh
the Copilot/Codex/Cursor versions.
```

- [ ] **Step 2: Write `conf/ai/README.md`**

Create `conf/ai/README.md`:
```markdown
# conf/ai — portable coding-assistant configuration

`claude/` holds the canonical Claude Code artifacts (symlinked into
`~/.claude`). `convert/` projects them onto Codex CLI, Copilot CLI, and
Cursor. See `docs/specs/2026-05-16-ai-assistant-portability-design.md`.

## Install

`evangelist install ai --mode 1` — run the deterministic converter, then
emit per-tool finalization prompts (agent QAs the output).

`evangelist install ai --mode 2` — emit per-tool delegation prompts; the
target assistant runs and, if needed, repairs the converter itself.

Rendered prompts land in `$XDG_CACHE_HOME/evangelist/ai-migration/`.

## After editing an artifact

The Claude artifacts are symlinked, so edits are saved immediately. The
other tools' files are generated — run `evangelist update ai` to refresh
them.

## Converter

`cd conf/ai && python3 -m convert.convert [--tool codex|copilot|cursor]
[--dry-run]`. Stdlib only. Tests: `python3 -m unittest discover
convert/tests`.
```

- [ ] **Step 3: Run the full test suite once more**

Run: `cd "$EVANGELIST/conf/ai" && python3 -m unittest discover convert/tests -v`
Expected: PASS — all adapter and core tests.

- [ ] **Step 4: Commit**

```bash
cd "$EVANGELIST"
git add conf/ai/claude/CLAUDE.md conf/ai/README.md
git commit -m "Document the ai config sync workflow

+ CLAUDE.md: note to run 'evangelist update ai' after edits
+ conf/ai/README.md: install modes, converter usage"
```

---

## Self-Review

- **Spec coverage:** repo layout (T2), symlink deployment (T2), converter
  core + adapters (T3–T8), command→skill mapping (T5/T6), Cursor native
  commands (T7), `CLAUDE.md`→instructions (T5/T6/T7), Mode 1/Mode 2 with
  self-heal (T9/T10), install/update/uninstall wiring (T11),
  converter-refresh note (T12), one-time audit (T1). MCP is handled by
  the prompt templates (T9), matching the spec's agent-handled decision.
- **Verify-at-implementation items:** Copilot `mcp-config.json` schema
  appears only in a note string (T6) and the finalize prompt; Cursor
  global skills path is flagged in a converter note (T7) — both degrade
  gracefully, no hard dependency.
- **Type consistency:** `Sources`, `Skill`, `Command`, `Conversion`
  used identically across `sources.py`, `emit.py`, all three adapters,
  and `convert.py`. Every adapter exposes `convert(sources, home) ->
  Conversion`.
- **No placeholders:** every code step contains complete files.
```
