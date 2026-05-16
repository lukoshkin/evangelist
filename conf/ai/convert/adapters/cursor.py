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
