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
