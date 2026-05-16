# conf/ai — portable coding-assistant configuration

`claude/` holds the canonical Claude Code artifacts (symlinked into
`~/.claude`). `convert/` projects them onto Codex CLI, Copilot CLI, and
Cursor. See `docs/specs/2026-05-16-ai-assistant-portability-design.md`.

## Install

`evangelist install ai [--tool T] [--mode M]`

- `--tool codex|copilot|cursor|all` — which assistant(s) to target.
- `--mode 1|2` — `1` runs the converter, then emits per-tool finalization
  prompts (the assistant QAs the output); `2` emits delegation prompts and
  the assistant runs / self-heals the converter itself.

Omit either flag and you are prompted for it. Both choices are persisted
under `$XDG_STATE_HOME/evangelist/` (`ai-tool`, `ai-mode`) and reused by
`evangelist update ai`. Rendered prompts land in
`$XDG_CACHE_HOME/evangelist/ai-migration/`.

## After editing an artifact

The Claude artifacts are symlinked, so edits are saved immediately. The
other tools' files are generated — run `evangelist update ai` to refresh
them.

## Converter

`cd conf/ai && python3 -m convert.convert [--tool codex|copilot|cursor]
[--dry-run]`. Stdlib only. Tests: `python3 -m unittest discover
convert/tests`.
