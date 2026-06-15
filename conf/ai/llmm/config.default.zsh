# llmm configuration — sourced by the llmm dispatcher (zsh).
# Precedence: env LLMM_* > this file > built-in defaults.

LLMM_PORT=${LLMM_PORT:-11111}
LLMM_MODEL=${LLMM_MODEL:-'unsloth/Qwen3-Coder-Next-GGUF:UD-Q3_K_M'}
# Alias shown in Claude Code and passed to llama-server --alias. Leave empty to
# auto-derive from the model (e.g. Qwen3-Coder-Next-UD-Q3_K_M); set to override.
LLMM_ALIAS=${LLMM_ALIAS:-}
LLMM_LOG_MAX_MIB=${LLMM_LOG_MAX_MIB:-50}   # rotate the server log past this size

# mmap: 0 = --no-mmap (load weights into RAM up front). Default 0 on macOS:
#   predictable RSS, no mid-generation page-in stalls, and avoids the Metal
#   warmup-time allocation OOM. Set 1 to memory-map (lazy, lower apparent RAM,
#   evictable under pressure) when a model barely fits.
typeset -gA LLMM_PROFILES=(
  default.ctx_size 65536  default.gpu_layers auto  default.flash_attn on  default.warmup 1  default.mmap 0
  minimal.ctx_size 16384  minimal.gpu_layers auto  minimal.flash_attn on  minimal.warmup 0  minimal.mmap 0
)
