# llmm configuration — sourced by the llmm dispatcher (zsh).
# Precedence: env LLMM_* > this file > built-in defaults.

LLMM_PORT=${LLMM_PORT:-11111}
LLMM_MODEL=${LLMM_MODEL:-'unsloth/Qwen3-Coder-Next-GGUF:UD-Q3_K_M'}
LLMM_LOG_MAX_MIB=${LLMM_LOG_MAX_MIB:-50}   # rotate the server log past this size

# Lean launch: strip Claude Code to a minimal, weak-model-friendly session
# (no MCP, trimmed tools, --bare, a slim replacement system prompt, and a context
# window the size of the real local window so auto-compaction fires in time).
# Lean is on by default; `llmm --full` opts out per launch, `llmm --lean` forces it.
LLMM_LEAN=${LLMM_LEAN:-1}
# Path to a minimal MCP config json to re-admit under lean (e.g. just context7).
# Empty = no MCP servers in lean mode.
LLMM_MCP_CONFIG=${LLMM_MCP_CONFIG:-}
# Path to a replacement system prompt for lean mode. Empty = the shipped
# prompts/lean-coder.md (tuned for Qwen-class coder models).
LLMM_SYSTEM_PROMPT=${LLMM_SYSTEM_PROMPT:-}
# Auto-compact threshold, percent of the window (lean only). 80 => compact near 80%.
LLMM_COMPACT_PCT=${LLMM_COMPACT_PCT:-80}
# Per-launch window override is `llmm --ctx N`; the persistent default lives in
# LLMM_PROFILES below (default.ctx_size). Raise it on machines with more RAM.

# The Claude-facing alias is derived from the model automatically
# (e.g. Qwen3-Coder-Next-UD-Q3_K_M) — no separate setting.

# mmap: 0 = --no-mmap (load weights into RAM up front). Default 0 on macOS:
#   predictable RSS, no mid-generation page-in stalls, and avoids the Metal
#   warmup-time allocation OOM. Set 1 to memory-map (lazy, lower apparent RAM,
#   evictable under pressure) when a model barely fits.
# ctx_checkpoints: max llama.cpp context checkpoints per slot (--ctx-checkpoints,
#   default upstream is 32 × ~75 MiB ≈ 2.4 GB). They only speed up reprocessing on
#   context shift; Claude Code compacts instead, so 8 trims ~1.8 GB on a full box.
# parallel: server slots (--parallel). Claude Code drives one conversation, so 1
#   is enough; with kv_unified the KV pool is unchanged, this just drops dead slots.
typeset -gA LLMM_PROFILES=(
  default.ctx_size 65536  default.gpu_layers auto  default.flash_attn on  default.warmup 1  default.mmap 0  default.ctx_checkpoints 8  default.parallel 1
  minimal.ctx_size 16384  minimal.gpu_layers auto  minimal.flash_attn on  minimal.warmup 0  minimal.mmap 0  minimal.ctx_checkpoints 8  minimal.parallel 1
)
