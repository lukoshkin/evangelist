"""Adapter: Claude Code artifacts -> OpenAI Codex CLI."""

from pathlib import Path

from convert.common import rewrite_script_paths, slug
from convert.emit import Conversion
from convert.sources import Command, Sources


def _codex_skill_body(name: str, body: str) -> str:
    body = rewrite_script_paths(body)

    if name == "bootstrap-project-docs":
        body = body.replace("CLAUDE.md", "AGENTS.md")
        body = body.replace("Claude sessions", "Codex sessions")

    if name == "jira-bootstrap":
        body = body.replace(
            """  4. Add to `~/.claude/settings.local.json`: `{ "env": { "JIRA_AUTH_TOKEN": "<token>" } }`
  5. Start a new Claude Code session so the var is loaded, then retry.""",
            """  4. Export `JIRA_AUTH_TOKEN` from the user's shell startup file or secret manager;
     do not store the token in `~/.codex/config.toml`
  5. Start a new Codex session so the environment variable is loaded, then retry.""",
        )

    return body


def _command_skill_body(cmd: Command) -> str:
    description = cmd.frontmatter.get("description") or next(
        (ln.strip() for ln in cmd.body.splitlines() if ln.strip()), cmd.name
    )
    body = rewrite_script_paths(cmd.body)
    if cmd.name == "uv-setup":
        body = body.replace(
            "AskUserQuestion",
            "`request_user_input` when available, or a concise plain-text question otherwise",
        )
    return f"---\nname: {slug(cmd.name)}\ndescription: {description}\n---\n{body}"


def convert(sources: Sources, home: Path) -> Conversion:
    conv = Conversion(tool="codex", tool_root=home / ".codex")
    skills_dir = home / ".agents" / "skills"

    for skill in sources.skills:
        dst = skills_dir / skill.name
        conv.trees[dst] = skill.directory
        skill_md = (skill.directory / "SKILL.md").read_text()
        conv.files[dst / "SKILL.md"] = _codex_skill_body(skill.name, skill_md)

    for cmd in sources.commands:
        conv.files[skills_dir / slug(cmd.name) / "SKILL.md"] = _command_skill_body(cmd)

    if sources.instructions:
        conv.files[home / ".codex" / "AGENTS.md"] = sources.instructions.read_text()

    conv.notes.append(
        "MCP servers are not converted — configure them in "
        "~/.codex/config.toml under [mcp_servers.<name>]."
    )
    return conv
