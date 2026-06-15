# llmm Lean Local-LLM Adaptation — Design

**Date:** 2026-06-15
**Status:** Approved (pending writing-plans)
**Predecessor:** `2026-06-15-llmm-local-llm-manager-design.md` (phase 1 — the manager itself)

## Problem

`llmm` launches Claude Code against a local `llama.cpp` server (Qwen3-Coder-Next,
`UD-Q3_K_M`). Phase 1 made that work; phase 2 makes it *usable* on a weak model
with a small context window.

The core issue is **fixed overhead crowding out a small window**, not the window
being too small to grow:

- The machine is an Apple **M5 Pro / 48 GB**. Qwen3-Coder-Next is an 80B-A3B MoE:
  **~36 GB of weights stay resident** regardless of quant. After the OS, only
  ~2–4 GB remain for KV cache, so the practical context ceiling is **~32K
  comfortable, 64K borderline** (with `-fa --swa-full` + Q8_0 KV). The model's
  native context is 256K and 128K is excellent — but that needs a 64 GB+ box.
  **"Grow the window" is therefore mostly off the table on this machine.**
- Against the 64K window, Claude Code's *fixed* cost is roughly: built-in tools
  **~24K** + MCP tool schemas **~17K** + system prompt **~3–4K** + memory
  **~4.5K** + skills **~4K** ≈ **~50K of 64K (~78%)**, leaving ~14K for real work.

Two consequences reshape the naive plan:

1. **Compaction cannot fix fixed overhead.** Auto-compaction only reclaims
   conversation/message tokens; it does nothing to system+tools+MCP+memory. The
   fix is to *cut the fixed overhead first*, then compaction has room to help.
2. **Claude Code assumes a 200K window for custom endpoints.** So today it never
   compacts before the 64K local server overflows (silent truncation/errors). We
   must *tell* it the real window.

## Goal

Add a **lean launch profile** (default on) that strips Claude Code down to a
minimal, Qwen-appropriate session — recovering ~35–40K of the window — and makes
Claude Code aware of the real context window so auto-compaction triggers correctly.
A **full profile** preserves today's behavior verbatim.

## Non-goals

- Changing the *default* server `ctx_size` (stays 65536). The window is fully
  configurable for portability and experimentation (see "Window sizing"); we just
  don't move the default off 64K for this machine. 32K is noted as the safe floor
  for 48 GB in docs, not enforced.
- Per-model automatic prompt selection (deferred to roadmap `Later`).
- Launching real Claude models (Sonnet/Opus) — `llmm` drives local models only.
- YaRN / >256K context extension.

## Architecture

All behavior funnels through **one seam — `lib/claude.zsh` / `claude::launch`** —
plus a small amount of config plumbing. No new modules; the leanness decision is
resolved by the dispatcher and passed in.

### Profile model

A **launch-leanness axis**, orthogonal to the existing server `ctx` profiles
(`default`/`minimal`):

- `LLMM_LEAN=1` (default **on**) in config.
- `llmm --full` opts out for a launch; `llmm --lean` forces it. The flag overrides
  the config value for that run only.
- Composes freely with the server profile: `llmm` = lean + default ctx;
  `llmm --full` = everything; `llmm --minimal` still selects the small-ctx
  *server* profile independently of leanness.

### What `lean` does

`claude::launch` builds a different argv + env when lean is active:

| Lever | Lean | Full |
|-------|------|------|
| MCP servers | `--strict-mcp-config` and **no** `--mcp-config` → all MCP dropped (unless `LLMM_MCP_CONFIG` set — see below) | default (all configured MCP) |
| Built-in tools | `--tools Bash Read Edit Write Grep Glob TodoWrite` | default (all) |
| Skills/hooks/LSP/plugins/auto-memory | `--bare` (all skipped) | default (all) |
| System prompt | `--system-prompt "$(<slim Qwen prompt>)"` (replace) | default Claude Code prompt |
| Context window | `CLAUDE_CODE_AUTO_COMPACT_WINDOW=<ctx_size>` | unset (CC default) |
| Compaction threshold | `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=<LLMM_COMPACT_PCT>` | unset |

Both env-var **names are doc-sourced but unverified**; see "Risks / verify-first".

### MCP: drop with opt-in knob

Lean drops **all** MCP by default — including `context7`. Rationale: the schema is
~1.9K, but worse, context7's doc dumps are token-heavy and swamp a 64K window on a
weak model.

Opt-in: `LLMM_MCP_CONFIG=<path>`. When set, lean passes
`--strict-mcp-config --mcp-config <path>`, re-admitting exactly the servers listed
(e.g. a minimal JSON with only context7). Default empty → no MCP.

### Slim Qwen system prompt

- Ships in-repo at **`conf/ai/llmm/prompts/lean-coder.md`** — terse, explicit
  tool-use instructions, no Claude-isms, ~400–700 tokens. Replaces (not appends)
  the ~3–4K default in lean.
- Override: `LLMM_SYSTEM_PROMPT=<path>` → use that file instead of the repo
  default. Empty → repo default.
- Full profile keeps Claude Code's default system prompt (no `--system-prompt`).

### Window sizing (portable + experiment-friendly)

The window is a first-class knob, not a constant:

- **Configured default** lives in `LLMM_PROFILES` (`default.ctx_size`, 65536).
  Other machines raise it for portability — a 64 GB box sets 131072 and everything
  downstream tracks. This box keeps 65536.
- **Per-launch override `llmm --ctx <N>`** for quick experiments without editing
  config. It feeds **both** the llama-server `--ctx-size` and
  `CLAUDE_CODE_AUTO_COMPACT_WINDOW`, so the model's real window and Claude Code's
  awareness of it stay in lock-step. Example: `llmm --ctx 81920` → 80K for that run.
- **Restart semantics:** llama-server fixes its context at process start, so an
  effective ctx that differs from an already-running server takes the existing
  `server::ensure` restart-prompt path (the running `.meta` records the ctx; a
  mismatch prompts to restart). No special-casing needed.
- **Soft caps only:** 80K on this 48 GB machine is past the ~64K borderline the
  research flagged — it may swap/OOM or slow down. That is the experiment, so
  `--ctx` is *not* hard-capped; the design allows any value and lets llama-server
  fail loudly if the machine can't hold it.

### Context-window awareness + compaction

- **Derive Claude Code's window from the effective `ctx_size`** (config default,
  or `--ctx` override) so they never drift: lean exports
  `CLAUDE_CODE_AUTO_COMPACT_WINDOW=<effective ctx_size>`. This fixes the
  200K-assumption bug.
- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=<LLMM_COMPACT_PCT>`, default **80** → compact at
  ~80% (~51K of a 64K window, scaling with whatever the window is). Tunable via
  `LLMM_COMPACT_PCT`.

## Config surface (new `LLMM_*` keys)

Seeded into `config.default.zsh` with comments:

| Key | Default | Meaning |
|-----|---------|---------|
| `LLMM_LEAN` | `1` | Lean launch on by default |
| `LLMM_MCP_CONFIG` | `""` | Path to a minimal MCP JSON to re-admit under lean; empty = no MCP |
| `LLMM_SYSTEM_PROMPT` | `""` | Path to a replacement system prompt; empty = repo `prompts/lean-coder.md` |
| `LLMM_COMPACT_PCT` | `80` | Auto-compact threshold % (only applied in lean) |

Precedence unchanged: env `LLMM_*` > config file > built-in defaults.

## Data flow

1. Dispatcher resolves leanness: `--lean`/`--full` flag > `LLMM_LEAN` > default 1.
2. Dispatcher resolves the effective `ctx_size`: `--ctx <N>` flag > active server
   profile's `ctx_size` > built-in default. The same value is passed to
   `server::ensure` (llama-server `--ctx-size`) **and** to `claude::launch`
   (`CLAUDE_CODE_AUTO_COMPACT_WINDOW`), guaranteeing lock-step. It also passes the
   leanness flag to `claude::launch`.
3. `claude::launch`:
   - Full → today's `exec env … claude "$@"` verbatim.
   - Lean → assemble env (existing ANTHROPIC_* + `CLAUDE_CODE_AUTO_COMPACT_WINDOW`
     + `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`) and argv (`--bare --strict-mcp-config`
     [`--mcp-config <LLMM_MCP_CONFIG>`] `--tools … --system-prompt <text>`) then
     `exec env … claude <lean args> "$@"`.

## Error handling

- If `LLMM_SYSTEM_PROMPT` is set but the file is missing → `ui::die` (explicit,
  no silent fallback — matches the project's "no swallowed errors" rule).
- If `LLMM_MCP_CONFIG` is set but missing → `ui::die`.
- If the repo `prompts/lean-coder.md` is missing → `ui::die` (install integrity).
- `LLMM_COMPACT_PCT` outside 1–99 → `ui::die` with the offending value.
- No try/catch-style swallowing; bad config fails loudly.

## Testing

- **Unit (existing zsh harness, `tests/test_*.zsh`):** stub `claude` to echo argv;
  assert `claude::launch` builds the correct argv/env for:
  - lean (no MCP): contains `--bare`, `--strict-mcp-config`, the exact `--tools`
    list, `--system-prompt`; sets `CLAUDE_CODE_AUTO_COMPACT_WINDOW` +
    `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`; **absent** `--mcp-config`.
  - lean + `LLMM_MCP_CONFIG`: now contains `--mcp-config <path>`.
  - full: none of the lean flags; no window env.
  - `--ctx <N>` override: the effective ctx flows to both
    `CLAUDE_CODE_AUTO_COMPACT_WINDOW` and the server `--ctx-size` (assert the
    dispatcher resolves `--ctx` > profile > default).
  - `LLMM_SYSTEM_PROMPT` override path is used when set.
  - validation: missing prompt/mcp file and out-of-range pct each `die`.
- **Manual smoke ("did it work"):** launch lean, read the `/context` meter,
  confirm fixed overhead drops from ~50K to ~10–12K and the window reads **64K not
  200K**. Record the before/after token budget in `conf/ai/README.md`.

## Risks / verify-first

- **Env-var names unverified.** `CLAUDE_CODE_AUTO_COMPACT_WINDOW` and
  `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` are from docs, not confirmed empirically. The
  **first implementation step** is a manual check: launch lean → does `/context`
  show `/64K`? does it compact near the threshold? If a name is wrong, find the
  real one (env-vars doc / `claude --help` / behavior) before wiring it in.
- **`--bare` + tool-calling.** Confirm replacing the system prompt and using
  `--bare` doesn't break the local model's ability to *call* tools (schemas are
  separate from prompt text, so expected fine — but verify on first run).
- **CLAUDE.md under `--bare`.** `--bare` skips auto-memory; confirm whether the
  global `~/.claude/CLAUDE.md` still loads, and whether that matters for token
  budget. If it still loads and is heavy, decide suppression via `--setting-sources`.

## Roadmap deltas

- `## Later`: per-model automatic prompt selection (point 3-ii); note 32K as the
  safe ctx floor for 48 GB machines.

## Documentation

- `conf/ai/README.md` `## llmm`: document the lean/full profiles, the new config
  keys, the MCP opt-in knob, and the before/after token budget.
- `config.default.zsh`: seed the four new keys with comments.
