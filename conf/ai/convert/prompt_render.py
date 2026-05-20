"""Render migration prompts with per-tool guidance."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

_PLACEHOLDER_RE = re.compile(r"@([A-Z_]+)@")


def _extras_path(ai_dir: Path, tool: str, phase: str) -> Path:
    return ai_dir / "convert" / "prompts" / "extras" / f"{tool}-{phase}.md"


def tool_extra_guidance(ai_dir: Path, tool: str, phase: str) -> str:
    path = _extras_path(ai_dir, tool, phase)
    if not path.is_file():
        return ""

    return path.read_text().strip() + "\n"


def render_template(template: str, replacements: dict[str, str]) -> str:
    rendered = template
    for key, value in replacements.items():
        rendered = rendered.replace(f"@{key}@", value)

    if unresolved := sorted(set(_PLACEHOLDER_RE.findall(rendered))):
        names = ", ".join(unresolved)
        raise ValueError(f"Unresolved placeholders: {names}")

    return rendered


def render_prompt(
    template_path: Path,
    ai_dir: Path,
    tool: str,
    phase: str,
    replacements: dict[str, str]
) -> str:
    render_values = dict(replacements)
    render_values["TOOL_EXTRA_GUIDANCE"] = tool_extra_guidance(ai_dir, tool, phase)
    return render_template(template_path.read_text(), render_values)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--template", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--tool", required=True)
    parser.add_argument("--phase", required=True, choices=("delegate", "finalize"))
    parser.add_argument("--ai-dir", required=True)
    parser.add_argument("--claude-src", required=True)
    parser.add_argument("--stamp-path", required=True)
    parser.add_argument("--current-tool-version", required=True)
    parser.add_argument("--recorded-tested-version", required=True)
    args = parser.parse_args()

    rendered = render_prompt(
        template_path=Path(args.template),
        ai_dir=Path(args.ai_dir),
        tool=args.tool,
        phase=args.phase,
        replacements={
            "TOOL": args.tool,
            "CLAUDE_SRC": args.claude_src,
            "AI_DIR": args.ai_dir,
            "STAMP_PATH": args.stamp_path,
            "CURRENT_TOOL_VERSION": args.current_tool_version,
            "RECORDED_TESTED_VERSION": args.recorded_tested_version,
        },
    )

    Path(args.output).write_text(rendered)


if __name__ == "__main__":
    main()
