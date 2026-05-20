"""Adapter: Claude Code artifacts -> GitHub Copilot CLI."""

import os
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


def _copilot_root(home: Path) -> Path:
    if copilot_home := os.environ.get("COPILOT_HOME"):
        return Path(copilot_home).expanduser()

    return home / ".copilot"


def convert(sources: Sources, home: Path) -> Conversion:
    copilot_root = _copilot_root(home)
    conv = Conversion(tool="copilot", tool_root=copilot_root)
    skills_dir = copilot_root / "skills"

    for skill in sources.skills:
        dst = skills_dir / skill.name
        conv.trees[dst] = skill.directory
        skill_md = (skill.directory / "SKILL.md").read_text()
        conv.files[dst / "SKILL.md"] = rewrite_script_paths(skill_md)

    for cmd in sources.commands:
        conv.files[skills_dir / slug(cmd.name) / "SKILL.md"] = _command_skill_body(cmd)

    if sources.instructions:
        target = copilot_root / "copilot-instructions.md"
        conv.files[target] = sources.instructions.read_text()

    conv.notes.append(
        "Copilot CLI local config is not converted — merge footer/status "
        f"settings in {copilot_root / 'settings.json'} and MCP servers in "
        f"{copilot_root / 'mcp-config.json'} using a top-level "
        "'mcpServers' object."
    )
    return conv
