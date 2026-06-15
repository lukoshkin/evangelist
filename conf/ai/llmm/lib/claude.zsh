#!/usr/bin/env zsh
# claude.zsh — launch Claude Code pointed at the local server.
# Two modes:
#   full — today's behavior (default system prompt, all tools, all MCP).
#   lean — minimal session for a weak local model: no MCP, trimmed tools, --bare,
#          a slim replacement system prompt, and a context window the size of the
#          real local window so auto-compaction triggers before the server overflows.

# Built-in tools kept in lean mode (the irreducible coding core).
typeset -ga CLAUDE_LEAN_TOOLS=(Bash Read Edit Write Grep Glob TodoWrite ExitPlanMode)

# claude::lean_prompt -> path to the lean system-prompt file (override or repo default).
# Dies if the resolved file is missing (bad override / broken install).
claude::lean_prompt() {
  local p="${LLMM_SYSTEM_PROMPT:-$LLMM_ROOT/prompts/lean-coder.md}"
  [[ -f "$p" ]] || ui::die "lean system prompt not found: $p"
  print -r -- "$p"
}

# claude::compact_pct -> validated auto-compact threshold percentage (integer 1..99).
claude::compact_pct() {
  local pct="${LLMM_COMPACT_PCT:-80}"
  if [[ "$pct" != <-> ]] || (( pct < 1 || pct > 99 )); then
    ui::die "LLMM_COMPACT_PCT must be an integer 1..99, got: $pct"
  fi
  print -r -- "$pct"
}

# claude::launch <alias> <port> <lean> <ctx> [claude args...]
# lean: 1 = lean session, 0 = full. ctx: effective context window (config::ctx_size).
# With LLMM_DRYRUN set, prints the assembled env/args (one per line) and returns
# instead of exec-ing — used by the test suite.
claude::launch() {
  local alias="$1" port="$2" lean="$3" ctx="$4"; shift 4
  local -a cenv cargs
  cenv=(
    ANTHROPIC_BASE_URL="http://127.0.0.1:$port"
    ANTHROPIC_API_KEY="llama-cpp"
    ANTHROPIC_AUTH_TOKEN="llama-cpp"
    ANTHROPIC_DEFAULT_SONNET_MODEL="$alias"
    ANTHROPIC_DEFAULT_HAIKU_MODEL="$alias"
    ANTHROPIC_DEFAULT_OPUS_MODEL="$alias"
    CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1
  )
  if [[ "$lean" == 1 ]]; then
    # Validate before building so bad config fails loudly and early.
    local prompt pct
    prompt="$(claude::lean_prompt)" || exit 1
    pct="$(claude::compact_pct)" || exit 1
    cenv+=(
      CLAUDE_CODE_DISABLE_1M_CONTEXT=1
      CLAUDE_CODE_MAX_CONTEXT_TOKENS="$ctx"
      CLAUDE_CODE_AUTO_COMPACT_WINDOW="$ctx"
      CLAUDE_AUTOCOMPACT_PCT_OVERRIDE="$pct"
    )
    cargs+=(--bare --strict-mcp-config)
    if [[ -n "${LLMM_MCP_CONFIG:-}" ]]; then
      [[ -f "$LLMM_MCP_CONFIG" ]] || ui::die "LLMM_MCP_CONFIG not found: $LLMM_MCP_CONFIG"
      cargs+=(--mcp-config "$LLMM_MCP_CONFIG")
    fi
    cargs+=(--tools "${CLAUDE_LEAN_TOOLS[@]}")
    # --system-prompt-file is a flag, so it terminates the variadic --tools list.
    cargs+=(--system-prompt-file "$prompt")
  fi
  if [[ -n "${LLMM_DRYRUN:-}" ]]; then
    local x
    for x in "${cenv[@]}";  do print -r -- "ENV $x"; done
    for x in "${cargs[@]}"; do print -r -- "ARG $x"; done
    for x in "$@";          do print -r -- "ARG $x"; done
    return 0
  fi
  exec env "${cenv[@]}" claude "${cargs[@]}" "$@"
}
