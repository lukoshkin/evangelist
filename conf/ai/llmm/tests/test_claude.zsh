source "$LLMM_LIB/ui.zsh"
source "$LLMM_LIB/config.zsh"
source "$LLMM_LIB/claude.zsh"

# The lean prompt ships, is non-empty, and is economical (< 700 words).
assert_eq "$([[ -f "$LLMM_ROOT/prompts/lean-coder.md" ]] && print yes)" yes "lean prompt file ships"
typeset _pw=$(wc -w < "$LLMM_ROOT/prompts/lean-coder.md")
assert_eq "$(( _pw > 0 && _pw < 700 ))" 1 "lean prompt non-empty and < 700 words"

# --- lean build (no MCP opt-in) ---
typeset out
out="$(LLMM_DRYRUN=1 claude::launch myalias 11111 1 65536 2>&1)"
assert_contains "$out" "ENV ANTHROPIC_BASE_URL=http://127.0.0.1:11111" "lean sets base url"
assert_contains "$out" "ENV ANTHROPIC_DEFAULT_SONNET_MODEL=myalias" "lean sets alias env"
assert_contains "$out" "ENV CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1" "lean keeps beta disable"
assert_contains "$out" "ENV CLAUDE_CODE_AUTO_COMPACT_WINDOW=65536" "lean sets real window"
assert_contains "$out" "ENV CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=80" "lean default compact pct"
assert_contains "$out" "ARG --bare" "lean passes --bare"
assert_contains "$out" "ARG --strict-mcp-config" "lean passes --strict-mcp-config"
assert_contains "$out" "ARG --tools" "lean passes --tools"
assert_contains "$out" "ARG Bash" "lean keeps Bash"
assert_contains "$out" "ARG TodoWrite" "lean keeps TodoWrite"
assert_contains "$out" "ARG --system-prompt-file" "lean replaces system prompt via file"
assert_not_contains "$out" "ARG --mcp-config" "lean omits --mcp-config when LLMM_MCP_CONFIG unset"
assert_not_contains "$out" "ARG Task" "lean drops Task/subagents"
assert_not_contains "$out" "ARG WebSearch" "lean drops WebSearch"

# --- full build: none of the lean flags, no window env ---
out="$(LLMM_DRYRUN=1 claude::launch myalias 11111 0 65536 2>&1)"
assert_not_contains "$out" "ARG --bare" "full omits --bare"
assert_not_contains "$out" "ARG --strict-mcp-config" "full omits --strict-mcp-config"
assert_not_contains "$out" "ARG --system-prompt-file" "full keeps default system prompt"
assert_not_contains "$out" "ENV CLAUDE_CODE_AUTO_COMPACT_WINDOW" "full omits window env"
assert_contains "$out" "ENV ANTHROPIC_BASE_URL=http://127.0.0.1:11111" "full still sets base url"

# --- extra claude args are forwarded in both modes ---
out="$(LLMM_DRYRUN=1 claude::launch myalias 11111 1 65536 --resume 2>&1)"
assert_contains "$out" "ARG --resume" "lean forwards extra args"

# --- LLMM_MCP_CONFIG opt-in re-admits --mcp-config <path> ---
typeset _mcp="$(mktemp)"; print '{}' > "$_mcp"
out="$(LLMM_MCP_CONFIG="$_mcp" LLMM_DRYRUN=1 claude::launch a 1 1 100 2>&1)"
assert_contains "$out" "ARG --mcp-config" "mcp opt-in adds --mcp-config"
assert_contains "$out" "ARG $_mcp" "mcp opt-in passes the path"
rm -f "$_mcp"

# --- LLMM_COMPACT_PCT override flows through ---
out="$(LLMM_COMPACT_PCT=70 LLMM_DRYRUN=1 claude::launch a 1 1 100 2>&1)"
assert_contains "$out" "ENV CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=70" "compact pct override flows"

# --- validation: each bad input dies (rc 1). Subshell so ui::die can't kill the harness. ---
assert_rc 1 "$( (LLMM_COMPACT_PCT=150 LLMM_DRYRUN=1 claude::launch a 1 1 100) >/dev/null 2>&1; print $? )" "bad compact pct dies"
assert_rc 1 "$( (LLMM_COMPACT_PCT=abc LLMM_DRYRUN=1 claude::launch a 1 1 100) >/dev/null 2>&1; print $? )" "non-integer compact pct dies"
assert_rc 1 "$( (LLMM_SYSTEM_PROMPT=/no/such/prompt.md LLMM_DRYRUN=1 claude::launch a 1 1 100) >/dev/null 2>&1; print $? )" "missing prompt override dies"
assert_rc 1 "$( (LLMM_MCP_CONFIG=/no/such/mcp.json LLMM_DRYRUN=1 claude::launch a 1 1 100) >/dev/null 2>&1; print $? )" "missing mcp config dies"
