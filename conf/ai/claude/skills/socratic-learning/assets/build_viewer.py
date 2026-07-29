#!/usr/bin/env python3
"""Render the learning corpus's markdown into a browsable static HTML viewer.

Run after any session that adds/updates topic files or INDEX.md:
    python3 build_viewer.py

Converts every topic .md (and block 00-overview.md) into a sibling .html via
pandoc (MathJax-rendered), then generates a root index.html from INDEX.md
that links to those rendered pages. Nothing here touches the .md files
themselves -- they remain the source of truth for resume-mode / editing.
"""
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).parent
CSS = "_assets/style.css"
SKIP_STEMS = {"_template", "_session"}


def render_md_to_html(md_path: Path, breadcrumb: str) -> None:
    html_path = md_path.with_suffix(".html")
    depth = len(md_path.relative_to(ROOT).parts) - 1
    css_rel = "../" * depth + CSS
    back_rel = "../" * depth + "index.html"

    subprocess.run(
        [
            "pandoc", str(md_path), "-s", "--mathjax",
            "-c", css_rel, "-o", str(html_path),
        ],
        check=True,
    )

    html = html_path.read_text()
    nav = f'<div class="nav">⟵ <a href="{back_rel}">Back to index</a> &nbsp;|&nbsp; {breadcrumb}</div>\n'
    html = html.replace("<body>", "<body>\n" + nav, 1)
    html_path.write_text(html)


def render_topics() -> None:
    for block_dir in sorted(ROOT.glob("[0-9][0-9]-*")):
        if not block_dir.is_dir():
            continue
        block_title = block_dir.name.split("-", 1)[1].replace("-", " ").title()
        for md_path in sorted(block_dir.glob("*.md")):
            if md_path.stem in SKIP_STEMS:
                continue
            label = "Overview" if md_path.stem == "00-overview" else md_path.stem.replace("-", " ").title()
            render_md_to_html(md_path, breadcrumb=f"{block_title} / {label}")


TOPIC_LINE = re.compile(r"^-\s+(\S+)\s+\[([^\]]+)\]\(([^)]+)\)\s*(.*)$")
BLOCK_LINE = re.compile(r"^##\s+(\d+)\.\s+(.*)$")

STATUS_CLASS = {"✅": "status-done", "⏳": "status-progress", "📋": "status-todo"}


def md_inline_to_html(text: str) -> str:
    text = re.sub(r"\*\(([^)]+)\)\*", r"<em>(\1)</em>", text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", text)
    return text


def build_index() -> None:
    index_md = (ROOT / "INDEX.md").read_text().splitlines()
    block_dirs = sorted(d for d in ROOT.glob("[0-9][0-9]-*") if d.is_dir())

    title = index_md[0].lstrip("# ").strip()
    budget_line = next((l for l in index_md if l.startswith("**Total budget:**")), "")

    body = [f"<h1>{title}</h1>", f'<p class="meta">{md_inline_to_html(budget_line)}</p>']

    total_done = total_topics = 0
    block_idx = -1
    current_items: list[str] = []

    def flush_block(header_line: str | None) -> None:
        nonlocal current_items
        if header_line is not None:
            body.append(header_line)
        if current_items:
            body.append('<ul class="topics">')
            body.extend(current_items)
            body.append("</ul>")
        current_items = []

    pending_header = None
    for line in index_md:
        m = BLOCK_LINE.match(line)
        if m:
            flush_block(pending_header)
            block_idx += 1
            overview_link = ""
            if block_idx < len(block_dirs) and (block_dirs[block_idx] / "00-overview.html").exists():
                rel = f"{block_dirs[block_idx].name}/00-overview.html"
                overview_link = f'<a class="overview-link" href="{rel}">overview</a>'
            num, rest = m.group(1), md_inline_to_html(m.group(2))
            pending_header = f'<div class="block-header"><h2>{num}. {rest}</h2>{overview_link}</div>'
            continue

        m = TOPIC_LINE.match(line)
        if m:
            status, title_text, path, rest = m.groups()
            total_topics += 1
            if status == "✅":
                total_done += 1
            cls = STATUS_CLASS.get(status, "")
            html_path = re.sub(r"\.md$", ".html", path)
            current_items.append(
                f'<li class="{cls}"><a href="{html_path}">{title_text}</a> '
                f'<span class="budget">{md_inline_to_html(rest)}</span></li>'
            )

    flush_block(pending_header)

    pct = int(100 * total_done / total_topics) if total_topics else 0
    progress = (
        f'<p class="meta">{total_done}/{total_topics} topics complete</p>'
        f'<div class="progress-bar"><div class="progress-fill" style="width:{pct}%"></div></div>'
    )
    body.insert(2, progress)

    session_link = '<p><a href="_session.html">Last session</a></p>' if (ROOT / "_session.html").exists() else ""
    body.append(session_link)

    html_doc = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>{title}</title>
<link rel="stylesheet" href="{CSS}">
</head>
<body>
{chr(10).join(body)}
</body>
</html>
"""
    (ROOT / "index.html").write_text(html_doc)


def render_session() -> None:
    render_md_to_html(ROOT / "_session.md", breadcrumb="Session log")


if __name__ == "__main__":
    render_topics()
    render_session()
    build_index()
    print("Viewer built: open index.html")
