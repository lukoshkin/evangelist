# conf/ai — portable coding-assistant configuration

`claude/` holds the canonical Claude Code artifacts (symlinked into
`~/.claude`). `convert/` projects them onto Codex CLI, Copilot CLI, and
Cursor. See `docs/specs/2026-05-16-ai-assistant-portability-design.md`.

## Install

`evangelist install ai [--tool T] [--mode M]`

- `--tool codex|copilot|cursor|all` — which assistant(s) to target.
- `--mode 1|2` — `1` runs the converter, then emits per-tool finalization
  prompts (the assistant QAs the output, handles tool-native local config
  the converter intentionally skips, and refreshes the tested-version
  stamp); `2` emits delegation prompts with the current/recorded tool
  version so the assistant can fast-path mechanical execution when the
  versions are close, then run / self-heal the converter, handle
  tool-native local config, and refresh the tested-version stamp.

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

## llmm — local-LLM manager

`llmm/` is a self-contained zsh tool that runs a local `llama.cpp` server
and launches Claude Code against it. It is structured as a future
standalone repo: a `llmm` dispatcher sourcing focused `lib/*.zsh` units
(`ui`, `config`, `models`, `server`, `status`, `claude`), a bash 3.2-safe
`install.sh`, and a self-contained zsh test harness under `tests/`.

### Install

`evangelist install llmm` (a thin shim over `conf/ai/llmm/install.sh`).
The installer builds `llama.cpp` from source into an XDG-local prefix
(`$XDG_DATA_HOME/llmm`, backend auto-detected: Metal on macOS, CUDA/
Vulkan/CPU on Linux — prompted when interactive), installs `uv` +
`huggingface_hub[cli]` for model downloads, symlinks `~/.local/bin/llmm`,
and seeds the config. Re-run after editing anything under `conf/ai/llmm/`
via `evangelist update` (it refreshes `llmm` automatically). Requires
`zsh` at runtime; `fzf` is optional (the picker falls back to a numbered
menu).

### Commands

- `llmm` — start the default model and launch Claude Code.
- `llmm pick` — pick a discovered model, then start + launch.
- `llmm [pick] --minimal` — use the minimal profile (small ctx, no warmup).
- `llmm pull <repo[:quant]>` — download a model into the dedicated store.
- `llmm status` (`stat`/`stats`) — system RAM + the managed server's
  pid/alias/model/RSS/ctx and log-parsed model/KV/Metal buffer sizes.
- `llmm logs [-f] [--tail N]` — tail the server log (default `--tail 100`).
- `llmm config` — open the config in `$EDITOR`.
- `llmm kill` — stop the running server.

### Config & storage

- Config: `$XDG_CONFIG_HOME/llmm/config.zsh` (seeded from
  `llmm/config.default.zsh`). Precedence: env `LLMM_*` > config file >
  built-in defaults. Two profiles (`default`, `minimal`) hold
  `ctx_size`/`gpu_layers`/`flash_attn`/`warmup`/`mmap`.
- Models: `$XDG_DATA_HOME/llmm/models` (`HF_HOME`); the built server lives
  under `$XDG_DATA_HOME/llmm/bin`.
- Runtime state: `$XDG_STATE_HOME/llmm/{run,log}` — per-port `.meta` +
  size-rotated logs (`LLMM_LOG_MAX_MIB`, default 50).

### Tests

`zsh conf/ai/llmm/tests/harness.zsh` runs the unit suite (pure helpers:
config precedence, model labels/discovery, arg building, meta round-trip,
log rotation/parsing, dispatcher routing). Server start/launch are
verified by manual smoke (a real `llama-server`).

v1 manages a single server. Multiple concurrent port-keyed servers are a
planned v1.1 extension (the `.meta`/log files are already port-keyed).
