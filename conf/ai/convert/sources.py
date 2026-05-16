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
