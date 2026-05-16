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
