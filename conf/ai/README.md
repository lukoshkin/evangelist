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
- `llmm [pick] --full` — full Claude Code session (default is **lean**: no MCP,
  trimmed tools, `--bare`, a slim Qwen-tuned system prompt, and a context window
  matched to the real local window). `--lean` forces lean explicitly.
- `llmm [pick] --ctx N` — override the context window for this launch (e.g.
  `--ctx 81920` for ~80K). Feeds both llama-server's `--ctx-size` and Claude
  Code's `CLAUDE_CODE_AUTO_COMPACT_WINDOW`.
- `llmm pull <repo[:quant]>` — download a model into the dedicated store.
- `llmm status` (`stat`/`stats`) — system RAM + the managed server's
  pid/alias/model/RSS/ctx and the model's on-disk size.
- `llmm logs [-f] [--tail N]` — tail the server log (default `--tail 100`).
- `llmm config` — open the config in `$EDITOR`.
- `llmm kill` — stop the running server.

### Config & storage

- Config: `$XDG_CONFIG_HOME/llmm/config.zsh` (seeded from
  `llmm/config.default.zsh`). Precedence: env `LLMM_*` > config file >
  built-in defaults. Two profiles (`default`, `minimal`) hold
  `ctx_size`/`gpu_layers`/`flash_attn`/`warmup`/`mmap`/`ctx_checkpoints`/`parallel`.
  `ctx_checkpoints` caps llama.cpp's per-slot context checkpoints (default 8; each
  is ~75 MiB, upstream default 32 ≈ 2.4 GB) — they only speed reprocessing on
  context shift, which Claude Code sidesteps by compacting, so trimming them frees
  RAM on a full box. `parallel` is the server slot count (default 1; Claude Code
  drives a single conversation). The Claude-facing alias is derived from the model
  name automatically (no separate setting).
  Lean-mode knobs: `LLMM_LEAN` (1 = lean by default), `LLMM_MCP_CONFIG` (path to a
  minimal MCP json to re-admit servers like context7 under lean; empty = none),
  `LLMM_SYSTEM_PROMPT` (replacement prompt path; empty = shipped
  `prompts/lean-coder.md`), and `LLMM_COMPACT_PCT` (auto-compact threshold %,
  default 80). The effective context window is `--ctx N` > the active profile's
  `ctx_size`; lean tells Claude Code that same window (via
  `CLAUDE_CODE_MAX_CONTEXT_TOKENS` + `CLAUDE_CODE_AUTO_COMPACT_WINDOW`) and
  disables its 1M-context classification (`CLAUDE_CODE_DISABLE_1M_CONTEXT`) so it
  doesn't size the window from the model's nominal 256K/1M. Without this Claude
  Code tags the endpoint `[1m]` and picks a ~100K auto-compact window that
  overflows the local server. With it, `/context` reads the real window (e.g.
  64K) and compaction fires at `LLMM_COMPACT_PCT`% of it (~52K at 80%).
- Models: `$XDG_DATA_HOME/llmm/models` (`HF_HOME`); the built server lives
  under `$XDG_DATA_HOME/llmm/bin`.
- Runtime state: `$XDG_STATE_HOME/llmm/{run,log}` — per-port `.meta` +
  size-rotated logs (`LLMM_LOG_MAX_MIB`, default 50).

### Tests

`zsh conf/ai/llmm/tests/harness.zsh` runs the unit suite (pure helpers:
config precedence, effective window resolution, model
labels/discovery/alias derivation, arg building, meta round-trip, log rotation,
dispatcher routing, and lean/full launch-arg assembly). Server start/launch
are verified by manual smoke (a real `llama-server`).

v1 manages a single server. Multiple concurrent port-keyed servers are a
planned v1.1 extension (the `.meta`/log files are already port-keyed).

### Why lean

A local model's context window is small (≈32–64K on a 48 GB Mac for
Qwen3-Coder-Next), but Claude Code's fixed overhead — built-in tools (~24K), MCP
tool schemas (~17K), system prompt (~3–4K), memory (~4.5K), skills (~4K) — can eat
~50K of it before any work begins. Compaction only reclaims conversation tokens,
not this fixed overhead, so the fix is to cut the overhead: lean mode drops the
fixed cost to **~1.8K** measured (system prompt ~0.6K, tools ~1.2K, no MCP /
memory / skills), leaving essentially the whole window for actual code. Note 32K
is the safe ctx floor on 48 GB; raise `default.ctx_size` (or use `--ctx`) on
machines with more RAM.

**Known limitation (sub-100K windows).** Claude Code v2.1.x floors the auto-compact
window at ~100K and reserves a fixed ~33% buffer, so on a server smaller than that
the `CLAUDE_CODE_MAX_CONTEXT_TOKENS` / `CLAUDE_CODE_AUTO_COMPACT_WINDOW` /
`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` env vars are inert (only `CLAUDE_CODE_DISABLE_1M_CONTEXT`
takes effect, dropping the `[1m]` tag). `/context` then shows a 100K window and
compaction fires at ~67K — slightly above a 64K server, so the top ~2K isn't a
reliable working area (llama.cpp context-shifts there rather than erroring). Treat
~60K as the practical ceiling on a 64K server and `/compact` manually if you near
it. The env vars are kept because they *do* apply once the window exceeds ~100K
(e.g. a 128K-ctx box), so the config stays correct for larger machines.
