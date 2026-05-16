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
