source "$LLMM_LIB/ui.zsh"
source "$LLMM_LIB/config.zsh"
source "$LLMM_LIB/status.zsh"

log="$LLMM_TESTS_DIR/fixtures/sample-server.log"
assert_eq "$(status::parse_log "$log" model)" "18234.50 MiB" "parse model size"
assert_eq "$(status::parse_log "$log" kv)"    "4096.00 MiB"  "parse kv size"
assert_contains "$(status::parse_log "$log" metal)" "MiB" "parse metal size"
