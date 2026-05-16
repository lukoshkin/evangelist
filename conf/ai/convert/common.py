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
