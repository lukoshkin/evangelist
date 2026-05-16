#!/usr/bin/env python3
"""Detect blank-line style violations around guard clauses and brackets.

Checks
------
1. **Guard clauses** — a single-body ``if`` whose only statement is
   ``return``, ``raise``, ``continue``, or ``break`` must be followed by
   one blank line to visually separate the early exit from the main flow.

2. **Closing brackets** — a line starting with ``)``, ``}``, or ``]``
   (multiline construct) must NOT be followed by a blank line, because
   the bracket already provides visual separation.

Usage
-----
    python3 check_guard_clauses.py file1.py [file2.py ...]
    python3 check_guard_clauses.py --self-test

Exit codes
----------
    0  No violations found.
    1  One or more violations found (details printed to stdout).
"""

import os
import re
import sys
import tempfile

## A guard body starts with one of these keywords as a whole word —
## `\b` stops `returns_x`/`continue_flag` from matching.
GUARD_BODY = re.compile(r"(return|raise|continue|break)\b")


def _strip_comment(s: str) -> str:
    """Drop a trailing ``# comment``, respecting simple string literals.

    A ``#`` inside a single- or double-quoted string is not treated as a
    comment. Escaped quotes and triple-quoted strings are not handled —
    guard-clause headers do not contain them in practice.
    """
    quote: str | None = None
    for idx, ch in enumerate(s):
        if quote:
            if ch == quote:
                quote = None
        elif ch in "\"'":
            quote = ch
        elif ch == "#":
            return s[:idx]

    return s


def _is_guard_header(stripped: str) -> bool:
    """True when ``stripped`` is a single-line ``if`` header (``if ...:``),
    tolerating a trailing inline comment."""
    if not stripped.startswith("if "):
        return False

    return _strip_comment(stripped).rstrip().endswith(":")


def check_guard_clauses(path: str) -> list[str]:
    with open(path) as f:
        lines = f.readlines()

    violations: list[str] = []

    for i, line in enumerate(lines):
        stripped = line.lstrip()
        if not _is_guard_header(stripped):
            continue

        if_indent = len(line) - len(stripped)

        if i + 1 >= len(lines):
            continue

        body = lines[i + 1]
        body_stripped = body.lstrip()
        body_indent = len(body) - len(body_stripped)

        # Guard body must be exactly one indent level deeper (4 spaces)
        if body_indent != if_indent + 4:
            continue
        if not GUARD_BODY.match(body_stripped):
            continue

        if i + 2 >= len(lines):
            continue

        after = lines[i + 2]
        after_stripped = after.lstrip()
        after_indent = len(after) - len(after_stripped) if after_stripped.strip() else 0

        # A "close pair" is a return/raise guard immediately followed by a
        # bare return — the function's own exit, no main flow to separate.
        is_close_pair = (
            body_stripped.startswith(("return", "raise"))
            and after_stripped.startswith("return")
        )
        # Consecutive guards form a cluster: the next line is itself an
        # `if` header whose body (one line further) is an early exit.
        after_is_guard = (
            _is_guard_header(after_stripped)
            and i + 3 < len(lines)
            and bool(GUARD_BODY.match(lines[i + 3].lstrip()))
        )
        # Violation: next line is non-blank, at the same indent as the if,
        # and is not an elif/else continuation, a close pair, or a guard
        # cluster.
        if (
            after_stripped.strip()
            and after_indent == if_indent
            and not after_stripped.startswith(("elif ", "else:"))
            and not is_close_pair
            and not after_is_guard
        ):
            violations.append(
                f"{path}:{i + 1}: guard clause not followed by blank line\n"
                f"    {line.rstrip()}\n"
                f"    {body.rstrip()}\n"
                f"  → {after.rstrip()}"
            )

    return violations


def check_bracket_blank_lines(path: str) -> list[str]:
    """Flag blank lines after closing brackets in multiline constructs."""
    with open(path) as f:
        lines = f.readlines()

    violations: list[str] = []

    for i, line in enumerate(lines):
        stripped = line.lstrip()

        if not stripped or stripped[0] not in ")]}":
            continue

        # Skip block headers / definitions (e.g. `):`, `) -> int:`)
        if stripped.rstrip().endswith(":"):
            continue

        # Only inside function/class bodies (indented code)
        indent = len(line) - len(stripped)
        if indent == 0:
            continue

        if i + 1 >= len(lines):
            continue

        # Next line must be blank
        if lines[i + 1].strip():
            continue

        if i + 2 >= len(lines):
            continue

        # Line after blank must be non-blank code
        after = lines[i + 2]
        if not after.strip():
            continue

        ## A dedent, or a def/class/decorator, marks a block boundary —
        ## the blank line there is structural, not stylistic. Don't flag it.
        after_indent = len(after) - len(after.lstrip())
        if after_indent < indent or after.lstrip().startswith(
            ("def ", "async def ", "class ", "@")
        ):
            continue

        violations.append(
            f"{path}:{i + 2}: unnecessary blank line"
            f" after closing bracket\n"
            f"    {line.rstrip()}\n"
            f"  → {after.rstrip()}"
        )

    return violations


def _self_test() -> None:
    """Run built-in fixtures covering each rule and known false positives."""
    cases = [
        ("guard not followed by blank line",
         "def f(x):\n    if not x:\n        return\n    work()\n", 1, 0),
        ("guard followed by blank line",
         "def f(x):\n    if not x:\n        return\n\n    work()\n", 0, 0),
        ("consecutive guard clauses are a cluster",
         "def f(x, y):\n    if not x:\n        return\n"
         "    if not y:\n        return\n", 0, 0),
        ("guard header with trailing comment",
         "def f(x):\n    if not x:  # bail out\n        return\n    work()\n", 1, 0),
        ("break is a guard terminator",
         "def f(seq):\n    for x in seq:\n        if x:\n            break\n"
         "        work()\n", 1, 0),
        ("return-prefixed identifier is not a guard",
         "def f(x):\n    if x:\n        returned = 1\n    work()\n", 0, 0),
        ("blank line after closing bracket",
         "def f():\n    y = g(\n        1,\n    )\n\n    use(y)\n", 0, 1),
        ("blank line before def after bracket is structural",
         "class C:\n    def a(self):\n        y = g(\n            1,\n        )\n\n"
         "    def b(self):\n        return 1\n", 0, 0),
    ]
    failures = 0

    for name, src, exp_guard, exp_bracket in cases:
        with tempfile.NamedTemporaryFile("w", suffix=".py", delete=False) as tmp:
            tmp.write(src)
            tmp_path = tmp.name

        got_guard = len(check_guard_clauses(tmp_path))
        got_bracket = len(check_bracket_blank_lines(tmp_path))
        os.unlink(tmp_path)

        if got_guard == exp_guard and got_bracket == exp_bracket:
            print(f"ok    {name}")
            continue

        failures += 1
        print(
            f"FAIL  {name}\n"
            f"      guard:   expected {exp_guard}, got {got_guard}\n"
            f"      bracket: expected {exp_bracket}, got {got_bracket}"
        )

    if failures:
        print(f"\n{failures} self-test failure(s).")
        sys.exit(1)

    print(f"\nAll {len(cases)} self-tests passed.")


def main() -> None:
    if len(sys.argv) == 2 and sys.argv[1] == "--self-test":
        _self_test()
        return

    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} file1.py [file2.py ...]", file=sys.stderr)
        sys.exit(1)

    all_violations: list[str] = []
    for path in sys.argv[1:]:
        all_violations.extend(check_guard_clauses(path))
        all_violations.extend(check_bracket_blank_lines(path))

    if all_violations:
        for v in all_violations:
            print(v)
        sys.exit(1)

    print(f"OK: no guard-clause violations in {len(sys.argv) - 1} file(s).")


if __name__ == "__main__":
    main()
