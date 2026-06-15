source "$LLMM_LIB/ui.zsh"

# ui::pick_index maps a 1-based choice string to a 0-based index, or -1 if invalid.
assert_eq "$(ui::pick_index 3 5)" 2 "ui::pick_index valid"
assert_eq "$(ui::pick_index 0 5)" -1 "ui::pick_index too-low"
assert_eq "$(ui::pick_index 6 5)" -1 "ui::pick_index too-high"
assert_eq "$(ui::pick_index abc 5)" -1 "ui::pick_index non-numeric"
assert_eq "$(ui::pick_index '' 5)" -1 "ui::pick_index empty"

source "$LLMM_LIB/config.zsh"

# Profile lookup reads dotted keys from LLMM_PROFILES.
typeset -gA LLMM_PROFILES=( default.ctx_size 65536  minimal.ctx_size 16384  minimal.warmup 0 )
assert_eq "$(config::pf default ctx_size)" 65536 "pf default"
assert_eq "$(config::pf minimal ctx_size)" 16384 "pf minimal"
assert_eq "$(config::pf minimal warmup)" 0 "pf minimal warmup"

# config::ctx_size: profile value by default; LLMM_CTX_OVERRIDE (set by `llmm --ctx N`) wins.
assert_eq "$(config::ctx_size default)" 65536 "ctx_size from profile"
LLMM_CTX_OVERRIDE=81920
assert_eq "$(config::ctx_size default)" 81920 "ctx_size honors override"
unset LLMM_CTX_OVERRIDE
assert_eq "$(config::ctx_size default)" 65536 "ctx_size back to profile after unset"

# config::data_dir / state_dir / models_dir honor XDG.
# Plain (not prefix) assignment: command-substitution subshells inherit even
# non-exported params, so $(config::data_dir) sees these. unset afterward so
# they don't leak into sibling test files sourced by the same harness shell.
XDG_DATA_HOME=/tmp/xdh
config::reset_dirs
assert_eq "$(config::data_dir)" /tmp/xdh/llmm "data_dir XDG"
assert_eq "$(config::models_dir)" /tmp/xdh/llmm/models "models_dir XDG"
XDG_STATE_HOME=/tmp/xsh
config::reset_dirs
assert_eq "$(config::state_dir)" /tmp/xsh/llmm "state_dir XDG"
unset XDG_DATA_HOME XDG_STATE_HOME

# Env precedence: a pre-set LLMM_PORT (in the environment, as the dispatcher
# would see it) survives sourcing a config that sets it; an unset one is filled.
typeset tmpcfg="$(mktemp)"
print 'LLMM_PORT=22222\nLLMM_MODEL=from-file' > "$tmpcfg"
export LLMM_PORT=99999
config::load "$tmpcfg"
assert_eq "$LLMM_PORT" 99999 "env beats file"
assert_eq "$LLMM_MODEL" from-file "file fills unset"
unset LLMM_PORT LLMM_MODEL
rm -f "$tmpcfg"

# Dispatcher routing: stub the heavy functions, assert the right one is called.
# Wrapped in a function (not a subshell) so assert_* update the harness counters,
# and so the dispatcher's `setopt err_return …` is localized via local_options.
_test_llmm_dispatch() {
  emulate -L zsh
  setopt local_options
  export LLMM_ROOT="$LLMM_ROOT"
  # Source dispatcher in "library mode" so it defines llmm::* without running main.
  LLMM_NO_MAIN=1 source "$LLMM_ROOT/llmm"

  # Stub side-effecting deps.
  server::ensure()   { print "ensure:$1:$2:$3:$4"; }
  server::meta_get() { return 1; }   # no running server meta — keep derived alias
  claude::launch()   { local a=$1 p=$2 l=$3 c=$4; shift 4; print "launch:$a:$p:$l:$c args:$*"; }   # alias:port:lean:ctx + forwarded
  models::pick()     { print "/picked/model-Q3_K_M.gguf"; }
  config::load()     { :; }
  LLMM_PORT=11111 LLMM_MODEL=/m.gguf

  assert_contains "$(llmm::route help 2>&1)" "usage" "route help"
  assert_rc 2 "$(llmm::route bogus >/dev/null 2>&1; echo $?)" "unknown subcommand rc"

  # Leanness + ctx propagate to claude::launch. Model /m.gguf -> alias "m";
  # default profile ctx_size 65536 (set in LLMM_PROFILES above).
  LLMM_LEAN=1
  assert_contains "$(llmm::route '' 2>&1)" "launch:m:11111:1:65536" "lean on by default"
  assert_contains "$(llmm::route --full 2>&1)" "launch:m:11111:0:65536" "--full disables lean"
  assert_contains "$(llmm::route --ctx 81920 2>&1)" "launch:m:11111:1:81920" "--ctx overrides window"
  LLMM_LEAN=0
  assert_contains "$(llmm::route '' 2>&1)" "launch:m:11111:0:65536" "LLMM_LEAN=0 honored"
  assert_contains "$(llmm::route --lean 2>&1)" "launch:m:11111:1:65536" "--lean forces lean"
  unset LLMM_LEAN

  # claude's own flags pass through llmm to claude (short forms too), while llmm
  # flags are still consumed and help/bogus keep their meaning.
  assert_contains "$(llmm::route -c 2>&1)" "args:-c" "short -c forwarded to claude"
  assert_contains "$(llmm::route --continue 2>&1)" "args:--continue" "long --continue forwarded"
  assert_contains "$(llmm::route -r mysess 2>&1)" "args:-r mysess" "short -r + value forwarded"
  assert_contains "$(llmm::route --resume 2>&1)" "args:--resume" "long --resume forwarded"
  assert_contains "$(llmm::route -c --ctx 81920 2>&1)" "launch:m:11111:1:81920 args:-c" "ctx consumed, -c forwarded"
  assert_contains "$(llmm::route --help 2>&1)" "usage" "--help shows llmm usage"
  assert_contains "$(llmm::route -h 2>&1)" "usage" "-h shows llmm usage"
}
_test_llmm_dispatch

# Shipped defaults parse under no_unset and define the lean knobs.
assert_eq "$( source "$LLMM_ROOT/config.default.zsh"; print -r -- "${LLMM_LEAN}" )" 1 "default LLMM_LEAN=1"
assert_eq "$( source "$LLMM_ROOT/config.default.zsh"; print -r -- "${LLMM_COMPACT_PCT}" )" 80 "default LLMM_COMPACT_PCT=80"
