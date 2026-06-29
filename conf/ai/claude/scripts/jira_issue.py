#!/usr/bin/env python3
"""Fetch Jira issue info, comments, and attachments via REST API v3."""

import argparse
import base64
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path


def make_session() -> tuple[str, str]:
    """Return (base_url, auth_header). Fail fast if env vars missing."""
    missing = [v for v in ("JIRA_URL", "JIRA_EMAIL", "JIRA_AUTH_TOKEN") if not os.environ.get(v)]
    if missing:
        print(f"Error: missing env vars: {', '.join(missing)}", file=sys.stderr)
        print("Set JIRA_URL and JIRA_EMAIL in ~/.claude/settings.json under 'env'.", file=sys.stderr)
        print("Set JIRA_AUTH_TOKEN in ~/.claude/settings.local.json under 'env'.", file=sys.stderr)
        sys.exit(1)
    base_url = os.environ["JIRA_URL"].rstrip("/")
    creds = base64.b64encode(
        f"{os.environ['JIRA_EMAIL']}:{os.environ['JIRA_AUTH_TOKEN']}".encode()
    ).decode()
    return base_url, f"Basic {creds}"


def jira_get(path: str, base_url: str, auth_header: str) -> dict:
    req = urllib.request.Request(
        f"{base_url}{path}",
        headers={"Authorization": auth_header, "Accept": "application/json"},
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        print(f"HTTP {e.code} for {path}: {body}", file=sys.stderr)
        sys.exit(1)


def adf_to_md(node: dict, _list_depth: int = 0) -> str:
    """Convert Atlassian Document Format node to Markdown string."""
    t = node.get("type", "")
    content = node.get("content", [])

    if t == "doc":
        parts = [adf_to_md(c) for c in content]
        return "\n\n".join(p for p in parts if p.strip())

    if t == "paragraph":
        return "".join(adf_to_md(c) for c in content)

    if t == "text":
        text = node.get("text", "")
        for mark in node.get("marks", []):
            mt = mark["type"]
            if mt == "strong":
                text = f"**{text}**"
            elif mt == "em":
                text = f"*{text}*"
            elif mt == "code":
                text = f"`{text}`"
            elif mt == "strike":
                text = f"~~{text}~~"
            elif mt == "link":
                href = mark.get("attrs", {}).get("href", "")
                text = f"[{text}]({href})"
        return text

    if t == "heading":
        level = node.get("attrs", {}).get("level", 1)
        return "#" * level + " " + "".join(adf_to_md(c) for c in content)

    if t == "hardBreak":
        return "\n"

    if t == "rule":
        return "---"

    if t == "mention":
        return node.get("attrs", {}).get("text", "@mention")

    if t == "emoji":
        return node.get("attrs", {}).get("text", "")

    if t == "inlineCard":
        url = node.get("attrs", {}).get("url", "")
        return f"<{url}>" if url else ""

    if t == "blockquote":
        inner = "\n\n".join(adf_to_md(c) for c in content)
        return "\n".join(f"> {line}" for line in inner.splitlines())

    if t == "codeBlock":
        lang = node.get("attrs", {}).get("language", "")
        code = "".join(c.get("text", "") for c in content if c.get("type") == "text")
        return f"```{lang}\n{code}\n```"

    if t == "bulletList":
        prefix = "  " * _list_depth + "- "
        lines = []
        for item in content:
            item_parts = [adf_to_md(c, _list_depth + 1) for c in item.get("content", [])]
            lines.append(prefix + "\n".join(item_parts))
        return "\n".join(lines)

    if t == "orderedList":
        prefix_base = "  " * _list_depth
        lines = []
        for i, item in enumerate(content, 1):
            item_parts = [adf_to_md(c, _list_depth + 1) for c in item.get("content", [])]
            lines.append(f"{prefix_base}{i}. " + "\n".join(item_parts))
        return "\n".join(lines)

    if t == "table":
        rows = []
        for row in content:
            cells = []
            for cell in row.get("content", []):
                cell_text = (
                    " ".join(adf_to_md(c) for c in cell.get("content", [])).replace("\n", " ")
                )
                cells.append(cell_text)
            rows.append("| " + " | ".join(cells) + " |")
            if len(rows) == 1:
                rows.append("| " + " | ".join("---" for _ in cells) + " |")
        return "\n".join(rows)

    if t in ("mediaSingle", "mediaGroup"):
        for child in content:
            if child.get("type") == "media":
                alt = child.get("attrs", {}).get("alt", "")
                return f"[attachment: {alt}]" if alt else "[attachment]"
        return "[media]"

    return "".join(adf_to_md(c) for c in content)


_FIELDS = ",".join([
    "summary",
    "description",
    "status",
    "assignee",
    "reporter",
    "priority",
    "labels",
    "components",
    "issuetype",
    "created",
    "updated",
    "comment",
    "attachment",
])


def _fmt_date(iso: str | None) -> str:
    return iso[:10] if iso else "—"


def _display_name(user: dict | None) -> str:
    if not user:
        return "Unassigned"
    return user.get("displayName", user.get("emailAddress", "Unknown"))


def format_issue_markdown(issue: dict) -> str:
    f = issue["fields"]
    key = issue["key"]
    lines = [
        f"# {key}: {f.get('summary', '')}",
        "",
        (
            f"**Status:** {f['status']['name']}  |  "
            f"**Type:** {f['issuetype']['name']}  |  "
            f"**Priority:** {(f.get('priority') or {}).get('name', '—')}"
        ),
        (
            f"**Assignee:** {_display_name(f.get('assignee'))}  |  "
            f"**Reporter:** {_display_name(f.get('reporter'))}"
        ),
        f"**Created:** {_fmt_date(f.get('created'))}  |  **Updated:** {_fmt_date(f.get('updated'))}",
    ]
    if f.get("labels"):
        lines.append(f"**Labels:** {', '.join(f['labels'])}")
    if f.get("components"):
        lines.append(f"**Components:** {', '.join(c['name'] for c in f['components'])}")

    lines += ["", "## Description", ""]
    desc = f.get("description")
    lines.append(adf_to_md(desc) if desc else "_No description._")

    attachments = f.get("attachment", [])
    if attachments:
        lines += ["", f"## Attachments ({len(attachments)})", ""]
        for att in attachments:
            size_kb = att.get("size", 0) // 1024
            lines.append(f"- **{att['filename']}** ({size_kb} KB)")
        lines.append(
            f"\n_To download: `python3 ~/.claude/scripts/jira_issue.py {key} download`_"
        )

    return "\n".join(lines), attachments

    comments = (f.get("comment") or {}).get("comments", [])
    if comments:
        lines += ["", f"## Comments ({len(comments)})", ""]
        for c in comments:
            author = _display_name(c.get("author"))
            date = _fmt_date(c.get("created"))
            lines.append(f"### {author} — {date}")
            lines.append("")
            body = c.get("body")
            lines.append(adf_to_md(body) if body else "_empty_")
            lines.append("")

    return "\n".join(lines)


_IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg"}


def local_files_section(attachments: list[dict], att_dir: Path) -> str:
    lines = ["", "## Local Files", ""]
    for att in attachments:
        filename = Path(att["filename"]).name
        path = att_dir / filename
        if not path.exists():
            continue
        if path.suffix.lower() in _IMAGE_EXTS:
            lines.append(f"![{filename}]({path})")
        else:
            lines.append(f"[{filename}]({path})")
    return "\n".join(lines)


def from_fetch(key: str, as_json: bool, att_dir: Path | None, base_url: str, auth: str) -> str:
    issue = jira_get(f"/rest/api/3/issue/{key}?fields={_FIELDS}", base_url, auth)
    if as_json:
        return json.dumps(issue, indent=2)
    md = format_issue_markdown(issue)
    if att_dir:
        md += local_files_section(issue["fields"].get("attachment", []), att_dir)
    return md


def from_download(key: str, target_dir: str | None, base_url: str, auth: str) -> None:
    issue = jira_get(f"/rest/api/3/issue/{key}?fields=attachment", base_url, auth)
    attachments = issue["fields"].get("attachment", [])
    if not attachments:
        print(f"No attachments on {key}.")
        return

    safe_key = "".join(c for c in key if c.isalnum() or c == "-")
    dest = Path(target_dir).resolve() if target_dir else Path(f"/tmp/jira/{safe_key}")
    dest.mkdir(parents=True, exist_ok=True)
    print(f"Downloading {len(attachments)} attachment(s) to {dest}/")

    for att in attachments:
        filename = Path(att["filename"]).name  # strip any directory components
        out_path = dest / filename
        if not out_path.resolve().is_relative_to(dest.resolve()):
            print(f"  ✗ {filename}: skipped (path traversal attempt)", file=sys.stderr)
            continue
        req = urllib.request.Request(
            att["content"],
            headers={"Authorization": auth},
        )
        try:
            with urllib.request.urlopen(req) as resp, open(out_path, "wb") as fh:
                fh.write(resp.read())
            size_kb = out_path.stat().st_size // 1024
            print(f"  ✓ {filename} ({size_kb} KB)")
        except urllib.error.HTTPError as e:
            print(f"  ✗ {filename}: HTTP {e.code}", file=sys.stderr)

    print(f"Done. Files in: {dest}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Fetch Jira issue data")
    parser.add_argument("key", help="Issue key, e.g. PROJ-123")
    parser.add_argument("--json", action="store_true", dest="as_json", help="Output raw JSON")
    parser.add_argument(
        "--attachment-dir",
        default=None,
        metavar="DIR",
        help="Append a Local Files section linking to downloaded attachments in DIR",
    )
    sub = parser.add_subparsers(dest="command")
    dl = sub.add_parser("download", help="Download attachments")
    dl.add_argument("--dir", default=None, help="Target directory (default: /tmp/jira/<KEY>/)")
    args = parser.parse_args()

    if "-" not in args.key:
        print(
            f"Error: '{args.key}' doesn't look like a full ticket ID.\n"
            "Expected format: PROJECT-NNN (e.g. PROJ-123).",
            file=sys.stderr,
        )
        sys.exit(1)

    base_url, auth = make_session()

    if args.command == "download":
        from_download(args.key, args.dir, base_url, auth)
    else:
        att_dir = Path(args.attachment_dir) if args.attachment_dir else None
        print(from_fetch(args.key, args.as_json, att_dir, base_url, auth))


if __name__ == "__main__":
    main()
