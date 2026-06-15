# `llmm` — local-LLM server manager + Claude Code launcher

**Date:** 2026-06-15
**Status:** Approved (design) — pending spec review
**Supersedes:** `conf/ai/lcpp.claude`

## Problem

`conf/ai/lcpp.claude` is a single ~160-line bash script that (a) launches a
`llama-server` instance and (b) starts `claude` pointed at it via
`ANTHROPIC_*` env vars. It has grown flag-by-flag (`--pick`, `--kill`,
`--minimal`-ish behavior, OOM workarounds) into a tangle. Configuration is
env-var-only, there is no way to inspect a running server, logs go to a
single clobbered `/tmp` file, there is no provisioning of `llama.cpp` or
model-download tooling, and it is not wired into `evangelist`'s install
flow.

This spec replaces it with `llmm`: a zsh tool with a subcommand surface, a
sourced config file, hardware-aware status, a from-source build + dependency
installer, and first-class `evn install llmm` integration. The directory is
laid out so it can later split into a standalone repo with no restructuring.

Out of scope (Phase 2, see Deferred): shrinking Claude Code's own context
footprint so small local context windows are usable.

## Decisions (locked)

- **Shell (tool):** zsh. macOS always ships zsh ≥5.x (no Bash 3.2 trap);
  matches the user's login shell. Assoc arrays, `${(f)}` splitting,
  `${0:A}` path resolution, and glob qualifiers are fair game.
- **Shell (installer):** bash, kept 3.2-safe. `install.sh` must bootstrap a
  bare machine where zsh is not guaranteed (and can install/flag a missing
  zsh). Any Bash-3.2-unsafe construct is called out in review.
- **Command name:** `llmm` (avoids clash with Simon Willison's `llm`).
- **Config:** a sourced zsh file at
  `${XDG_CONFIG_HOME:-$HOME/.config}/llmm/config.zsh`. Repo ships a
  version-controlled default that seeds the user copy. Precedence:
  env var `LLMM_*` > user config file > built-in defaults.
- **Install:** a **new `llmm` evangelist component** (`evn install llmm`)
  that is a **thin shim** over `conf/ai/llmm/install.sh` (the canonical,
  standalone-capable installer).
- **llama.cpp:** **built from source**, OS- and arch-aware, into an
  XDG-local prefix. Linux compute backend is **prompted at install time
  with an auto-detected default pre-selected**; the non-interactive `evn`
  path uses the detected default without prompting. macOS = Metal (auto).
- **Model download/storage:** dedicated dir
  `${XDG_DATA_HOME:-$HOME/.local/share}/llmm/models` (via `HF_HOME`).
  Default path is the **HuggingFace CLI** (`hf`, installed through `uv`);
  **fallback** is llama-server's built-in `--hf-repo` downloader pointed at
  the same dir, used when `uv`/`hf` are unavailable. `llmm pull` exposes it.
- **Status:** dedicated `llmm status` (aliases `stat`/`stats`),
  hardware-oriented (RSS, ctx/KV/buffer sizes, system RAM headroom).
- **Concurrency:** **single managed server for v1.** Port-keyed multiple
  servers (with picker in `logs`/`status`/`kill`) is a v1.1 extension.
- **mmap:** configurable per-profile, default `0` (no-mmap) on macOS.
- **Logs:** truncate-on-start + single size-capped rotation; bounded tail
  on display.
- **Default model:** `unsloth/Qwen3-Coder-Next-GGUF:UD-Q3_K_M`.

## Command surface

`llmm` is a single dispatcher symlinked onto PATH. Subcommands:

| Command | Behavior |
|---|---|
| `llmm` | Ensure the default model's server is healthy (reuse if up; start if not), then exec `claude` against it. |
| `llmm pick` | fzf (numbered fallback) picker over local + dedicated-dir + HF-cache models, then ensure-server + exec `claude`. |
| `llmm [pick] --minimal` | As above using the `minimal` profile (reduced ctx, no warmup). |
| `llmm pull <repo[:quant]>` | Download a model into the dedicated dir (hf CLI; `--hf-repo` fallback). |
| `llmm status` (`stat`/`stats`) | Hardware-oriented report for the managed server + system memory line. |
| `llmm logs [-f] [--tail N]` | Tail the managed server's log (default `--tail 100`); `-f` follows. |
| `llmm config` | Open user config in `$EDITOR` (seed from default template if absent). |
| `llmm kill` | Kill the managed server (confirm). |
| `llmm help` | Usage. |

Parsing: the first token selects the subcommand; remaining flags are parsed
by that subcommand. `--minimal` is valid only on the start paths (bare /
`pick`). Unknown subcommand → `help` + non-zero exit.

### Start semantics (single-server v1)

When a start path runs (`llmm`, `llmm pick`, `--minimal`):

1. If a healthy managed server is on `LLMM_PORT`:
   - If its recorded model+profile match the request → **reuse**, exec `claude`.
   - If they differ → prompt: restart with the new config (kill + start) or
     reuse the running one. Non-interactive (`TERM=dumb`) → reuse + warn.
2. If no healthy server → start one with the resolved profile, wait for
   `/health`, then exec `claude`.
3. If something is listening on `LLMM_PORT` that llmm did not start (no
   run-state file) → treat as foreign: do not kill it; warn and reuse if it
   answers `/health`, else error with guidance.

`SERVE_ONLY=1 llmm …` ensures the server and blocks (`tail -f /dev/null`)
without launching claude — preserves the existing serve-only debug behavior.

## Build & dependency installer (`install.sh`)

`conf/ai/llmm/install.sh` is the canonical installer — bash, 3.2-safe, and
self-contained so the directory can become a standalone repo whose root is
this script. `evn install llmm` calls it; a standalone user runs it directly.

Steps (idempotent; safe to re-run):

1. **Detect** OS (`uname -s`) and arch (`uname -m`): macOS/arm64,
   macOS/x86_64, Linux/x86_64, Linux/arm64.
2. **Ensure base deps:** `git`, `cmake`, a C/C++ toolchain, `curl`. macOS:
   nudge to Xcode CLT + `brew install cmake`. Linux: detect the package
   manager and print the install line (don't silently `sudo`).
3. **Pick compute backend:**
   - macOS → Metal (no choice).
   - Linux → auto-detect: `nvidia-smi` present ⇒ default CUDA; else CPU
     (OpenBLAS). Prompt with that default pre-filled; non-interactive uses
     the default. Honor `LLMM_BACKEND=cuda|vulkan|cpu` to skip the prompt.
     If a GPU backend is chosen but its toolkit (e.g. `nvcc`) is missing,
     warn and offer to fall back to CPU.
4. **Build llama.cpp from source** into the XDG-local prefix (below),
   passing backend cmake flags (`-DGGML_METAL=ON`, `-DGGML_CUDA=ON`, …).
5. **Ensure `uv`** (official installer if absent) and
   `uv tool install "huggingface_hub[cli]"` to provide `hf`. On failure,
   warn that model pulls will fall back to `--hf-repo`.
6. **Ensure `zsh`** (the tool needs it). If absent, print the install line
   for the platform; do not hard-fail the build.
7. **`fzf`** — optional; warn if missing (picker degrades to numbered menu).
8. **Symlink** `conf/ai/llmm/llmm` → `~/.local/bin/llmm` (refuse to clobber
   a non-symlink without `--force`, matching `conf/ai/install.sh`).
9. **Seed** `~/.config/llmm/config.zsh` from `config.default.zsh` if absent.

`--force` backs up a conflicting regular file at the symlink target to
`<file>.pre-evangelist.bak`. `--rebuild` forces a clean llama.cpp rebuild.

### Build prefix (XDG-local)

```
${XDG_DATA_HOME:-$HOME/.local/share}/llmm/
  src/llama.cpp/        # git clone, build dir
  bin/                  # installed llama-server, llama-cli, *.dylib/*.so
  models/               # dedicated model store (HF_HOME points here)
```

No sudo, self-contained, easy to wipe and rebuild. `llmm` prepends
`…/llmm/bin` when locating `llama-server` and sets `DYLD_LIBRARY_PATH`
(macOS) / `LD_LIBRARY_PATH` (Linux) to it for the launch only — never
exported to claude, never with a trailing colon. A `llama-server` already
on PATH is used only if the built one is absent.

## Config & profiles

`config.default.zsh` (repo) → seeded to `~/.config/llmm/config.zsh`:

```zsh
# llmm configuration — sourced by the llmm dispatcher.
LLMM_PORT=11111
LLMM_MODEL='unsloth/Qwen3-Coder-Next-GGUF:UD-Q3_K_M'
LLMM_ALIAS=qwen3-coder-next
LLMM_LOG_MAX_MIB=50          # rotate the server log past this size
# EDITOR is honored for `llmm config`; falls back to VISUAL then a default.

# mmap: 0 = --no-mmap (load weights into RAM up front). Default 0 on macOS:
#   predictable RSS, no page-in stalls mid-generation, and avoids the
#   Metal warmup-time allocation OOM. Set 1 to memory-map (lazy load,
#   lower apparent RAM, evictable under pressure) when a model barely fits.
typeset -gA LLMM_PROFILES=(
  default.ctx_size 65536  default.gpu_layers auto  default.flash_attn on  default.warmup 1  default.mmap 0
  minimal.ctx_size 16384  minimal.gpu_layers auto  minimal.flash_attn on  minimal.warmup 0  minimal.mmap 0
)
```

- Profiles are a single assoc array keyed `<profile>.<field>` (dotted) so
  the launcher can look up `LLMM_PROFILES[$profile.ctx_size]` by dynamic
  profile name without zsh indirect-subscript gymnastics. Adding
  `profile_big` later is one line group with the `big.` prefix.
- `--minimal` selects `profile_minimal`; default path selects
  `profile_default`.
- Env override: any `LLMM_*` set in the environment wins over the file. The
  loader captures pre-set env vars, sources the file, then re-applies them.
- A `pick`ed model overrides `LLMM_MODEL`/`LLMM_ALIAS` for that run
  (alias derived from the basename).

## Code layout

```
conf/ai/llmm/            # == root of the future standalone repo
  llmm                   # dispatcher (symlinked to ~/.local/bin/llmm)
  install.sh             # canonical build + deps installer (bash, 3.2-safe)
  config.default.zsh     # seeded into ~/.config/llmm/config.zsh
  lib/
    config.zsh           # locate/seed/source config; resolve profile + env precedence
    models.zsh           # discover (dedicated dir + HF hub + state dir, find -L) + pick + pull
    server.zsh           # start / health-wait / kill; run-state (.meta) + log files + rotation
    status.zsh           # status report: ps RSS, sysctl/vm_stat mem, parse server log
    claude.zsh           # exec claude with ANTHROPIC_* env
    ui.zsh               # color/log helpers, numbered menu, fzf wrapper
```

The dispatcher resolves its own real path with `${0:A}` (follows the PATH
symlink back to the repo) and sources `lib/*.zsh` from there. Symlinked
edits stay live — same model as the rest of evangelist. Each lib unit has
one purpose and communicates via documented functions (e.g.
`server::ensure <profile> <model> <alias>`, `models::discover` → array,
`models::pull <repo>`, `status::report`).

## Runtime state & storage

`${XDG_STATE_HOME:-$HOME/.local/state}/llmm/`:

- `run/<port>.meta` — written at start: `pid`, `model`, `alias`,
  `ctx_size`, `profile`, `started_at`, `logfile`. Read by
  `status`/`logs`/`kill`. Removed on clean kill / detected-dead.
- `log/<port>.log` (+ `.log.1` rotation) — that server's stdout+stderr.

`${XDG_DATA_HOME:-$HOME/.local/share}/llmm/models` — the dedicated model
store; `HF_HOME` (and `LLAMA_CACHE` for the fallback downloader) point here
so both download paths converge. Discovery scans this dir, the HF hub
layout under it (`find -L`, dereferencing the `snapshots/*.gguf` symlinks),
and the legacy `$XDG_STATE_HOME/models`.

`server::*` treats a `.meta` whose pid is dead as stale and cleans it up.
v1 manages a single port (`LLMM_PORT`); the `<port>` keying already supports
v1.1 multi-server with no state-format change.

### Log rotation

On server start: if `log/<port>.log` exceeds `LLMM_LOG_MAX_MIB`, move it to
`log/<port>.log.1` (one backup), then truncate (`>`). Display via
`llmm logs` reads a bounded tail (`--tail 100` default), so it never loads
the whole file. No external `logrotate`/`newsyslog` dependency.

## `llmm status` internals

For the managed server (run-state file; fallback `pgrep -f llama-server`):

- **pid / port / alias / model / profile** — from `.meta`.
- **RSS** — `ps -o rss= -p <pid>` (KiB → MiB).
- **ctx / KV / model / Metal buffer sizes** — parsed from that server's
  startup log by matching llama.cpp's labels (regex on
  `llama_kv_cache.*size`, `Metal.*buffer size`, `model size`), tolerant of
  surrounding version drift. Parsed once per invocation.
- **System line** — `sysctl -n hw.memsize` (total; = unified GPU budget on
  Apple Silicon) and `vm_stat` (free/inactive pages) →
  e.g. `RAM 18.2 / 64 GiB used (28%)`. On Linux: `/proc/meminfo`.

Goal: one glance shows whether the current model leaves headroom and whether
a larger quant would fit — serving "pick the proper model for my hardware."
With no server running, `status` prints the system line plus "no managed
server running."

## llama-server launch flags (carried over)

`--alias --port --ctx-size --flash-attn on --jinja --n-gpu-layers`, plus
`--no-warmup` when `warmup=0` and `--no-mmap` when `mmap=0`. `--model
<path>` for a local/dedicated-dir/HF-cache file, else `--hf-repo <repo>`
(with the "first run downloads…" notice and `HF_HOME` set to the dedicated
dir). Library path scoped inline to the launch. Health wait: poll `/health`
up to 600 s; on timeout, dump the log tail and exit non-zero.

## `evn install llmm` integration

- `_impl/install.bash4`: `install::llmm_settings()` — a thin shim that runs
  `conf/ai/llmm/install.sh` with the appropriate flags (`--force` from the
  component's `--force`), records the component in evangelist state, and
  reports success/failure. No build logic duplicated in evn.
- `_impl/control.sh`: add the `llmm)` install case; add `conf/ai/llmm/` to
  the update trigger so `evn update llmm` re-runs `install.sh` (repairs the
  symlink, reseeds a missing config, rebuilds only with `--rebuild`; never
  overwrites an existing user config).
- `.update-list`, shell completions (`_impl/completions/`),
  `control::help`, and `write::modulecheck` (optional probes:
  `o:cmake o:llama-server o:fzf o:uv`) updated to include `llmm`.

## Migration

- `conf/ai/lcpp.claude` is removed (superseded). The manual
  `~/.local/bin/lcpp.claude` symlink is replaced by `~/.local/bin/llmm`.
- `conf/ai/lclaude` (Ollama launcher) stays as-is, out of scope. A future
  `backend=ollama|llamacpp` config switch could fold it in (Deferred).

## Testing

zsh has no ubiquitous unit harness; verification is script-level:

- `zsh -n` on the dispatcher and every `lib/*.zsh`; `bash -n` on `install.sh`.
- `models::discover` against a fixture tree (fake dedicated dir + fake HF
  hub with a symlinked `.gguf`, repo name containing `--`) to confirm
  `find -L` resolution and label formatting.
- Config precedence: env var beats file beats default.
- Profile resolution: `--minimal` yields the minimal assoc values.
- Dispatcher routing: each subcommand + `help` + unknown-subcommand exit
  code, asserted without starting a real server (stub `server::ensure`).
- `install.sh` dry-run on macOS + Linux: backend detection picks the right
  default; missing-toolkit fallback path; idempotent re-run.
- Manual smoke: real `llmm`, `llmm pull`, `llmm pick`, `llmm status`,
  `llmm logs`, `llmm kill` against a freshly built `llama-server`.

## Deferred

**v1.1 — multiple concurrent servers.** Port-keyed servers may coexist;
`logs`/`status`/`kill` auto-target when one runs and show a picker when
several do. The `run/<port>.meta` + `log/<port>.log` keying already supports
this; v1.1 adds the picker and a `--port` selector and drops the
single-server reuse/restart prompt.

**Phase 2 — Claude Code context-footprint reduction.** On a small local
context window (~64k), the system prompt + tool definitions + memory consume
~50% before any conversation. Reducing that (trimming tool sets, slimming
injected instructions for local-model sessions) is a separate effort
tackled after this tool lands. Logged to roadmap `Later`.

**Backend abstraction.** A `backend=ollama|llamacpp` config switch could
unify `llmm` with the existing `lclaude` Ollama launcher.

**Standalone repo split.** `conf/ai/llmm/` is laid out as the eventual repo
root (`install.sh` at top, self-contained). Splitting it out later means
extracting the directory and pointing `evn`'s shim at the cloned location.
