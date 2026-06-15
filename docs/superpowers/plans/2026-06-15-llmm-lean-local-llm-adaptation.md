# llmm Lean Local-LLM Adaptation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a lean Claude Code launch profile (default on) that strips the session down to a Qwen-appropriate minimum and makes Claude Code aware of the real local context window, so a weak local model isn't crowded out by ~50K of fixed overhead.

**Architecture:** All behavior funnels through one seam — `lib/claude.zsh` / `claude::launch` — plus small config + dispatcher plumbing. `claude::launch` builds `cenv`/`cargs` arrays and `exec`s them; a `LLMM_DRYRUN` hook prints them instead, making the lean/full decision unit-testable. A new `config::ctx_size` is the single source of truth for the effective context window (per-launch `--ctx N` override > profile), fed identically to llama-server's `--ctx-size` and Claude Code's `CLAUDE_CODE_AUTO_COMPACT_WINDOW`.

**Tech Stack:** zsh (dispatcher + libs), self-contained zsh test harness (`tests/harness.zsh`), llama.cpp `llama-server`, Claude Code CLI.

**Spec:** `docs/superpowers/specs/2026-06-15-llmm-lean-local-llm-adaptation-design.md`

**Conventions for the implementer:**
- Run the test suite with: `zsh conf/ai/llmm/tests/harness.zsh` — success prints `ran N assertions, 0 failure(s)` and exits 0.
- `ui::die` calls `exit 1`. Any test that exercises a `die` path MUST run the call in a subshell `( … )` and capture `$?`, or it will kill the harness.
- Prefix env assignments (`FOO=bar cmd`) do NOT apply to a `$(…)` argument that is expanded *before* the command runs. When a test needs an env var visible inside a `$(…)`, set it on its own line (or inside the subshell) and `unset` afterward — follow the existing patterns in `tests/test_config.zsh`.
- Commit messages follow the `git-commit` skill house style and MUST end with the `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>` trailer. Commit on `master` (this project commits directly on master).
- Do NOT run `git push`.

---

### Task 1: Effective context-window helper (`config::ctx_size`) + server wiring

Introduce a single override-aware accessor for the context window and route the two existing `ctx_size` reads through it, so `--ctx N` (added in Task 4) propagates everywhere with no drift.

**Files:**
- Modify: `conf/ai/llmm/lib/config.zsh` (add `config::ctx_size` after `config::pf`, ~line 14)
- Modify: `conf/ai/llmm/lib/server.zsh` (line 29 in `server::build_args`; line 100 in `server::start`)
- Test: `conf/ai/llmm/tests/test_config.zsh` (append after the `config::pf` assertions, ~line 16)

- [ ] **Step 1: Write the failing test**

Append to `conf/ai/llmm/tests/test_config.zsh` immediately after line 16 (`assert_eq "$(config::pf minimal warmup)" 0 "pf minimal warmup"`). `LLMM_PROFILES` with `default.ctx_size 65536` is already defined at line 13.

```zsh
# config::ctx_size: profile value by default; LLMM_CTX_OVERRIDE (set by `llmm --ctx N`) wins.
assert_eq "$(config::ctx_size default)" 65536 "ctx_size from profile"
LLMM_CTX_OVERRIDE=81920
assert_eq "$(config::ctx_size default)" 81920 "ctx_size honors override"
unset LLMM_CTX_OVERRIDE
assert_eq "$(config::ctx_size default)" 65536 "ctx_size back to profile after unset"
```

- [ ] **Step 2: Run the suite to verify it fails**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: FAIL — `command not found: config::ctx_size` (and a nonzero exit).

- [ ] **Step 3: Implement `config::ctx_size`**

In `conf/ai/llmm/lib/config.zsh`, add directly after the `config::pf` function (after line 14):

```zsh
# config::ctx_size <profile> -> effective context window. The per-launch override
# (LLMM_CTX_OVERRIDE, set by `llmm --ctx N`) wins; otherwise the profile's ctx_size.
# Single source of truth so llama-server's --ctx-size and Claude Code's
# CLAUDE_CODE_AUTO_COMPACT_WINDOW never drift.
config::ctx_size() {
  if [[ -n "${LLMM_CTX_OVERRIDE:-}" ]]; then
    print -r -- "$LLMM_CTX_OVERRIDE"
  else
    config::pf "$1" ctx_size
  fi
}
```

- [ ] **Step 4: Run the suite to verify it passes**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: PASS — `ran N assertions, 0 failure(s)`.

- [ ] **Step 5: Route the two server reads through the helper**

In `conf/ai/llmm/lib/server.zsh`, replace line 29 (inside `server::build_args`):

```zsh
  a+=(--ctx-size "$(config::ctx_size "$profile")")
```

and line 100 (inside `server::start`, the `server::meta_write` call):

```zsh
      server::meta_write "$port" "$pid" "$model" "$alias" "$(config::ctx_size "$profile")" "$profile"
```

- [ ] **Step 6: Re-run the suite (no regressions)**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: PASS — `ran N assertions, 0 failure(s)`.

- [ ] **Step 7: Commit**

```bash
git add conf/ai/llmm/lib/config.zsh conf/ai/llmm/lib/server.zsh conf/ai/llmm/tests/test_config.zsh
git commit   # house style; subject e.g. "Add config::ctx_size override-aware window accessor"
```

---

### Task 2: Ship the slim Qwen lean system prompt

Create the in-repo replacement system prompt used by lean mode. Terse, explicit tool-use guidance for a Qwen-class coder model, no Claude-isms, economical for a small window.

**Files:**
- Create: `conf/ai/llmm/prompts/lean-coder.md`

- [ ] **Step 1: Create the prompt file**

Create `conf/ai/llmm/prompts/lean-coder.md` with exactly this content:

```markdown
You are a coding assistant working in a terminal on the user's project. You act through tools and keep talking to a minimum.

# Tools
- Bash: run shell commands (build, test, git, run scripts). Quote paths. Avoid interactive commands.
- Read: read a file before you change it. Never guess a file's contents.
- Edit: change a file by replacing an exact, unique string. The old string must match the file character-for-character, including indentation.
- Write: create a new file, or fully overwrite one you have already read.
- Grep: search file contents by regex. Use it to find code instead of guessing where things are.
- Glob: find files by name pattern.
- TodoWrite: for a task with several steps, record the steps and mark them done as you go. Keep it short.

# How to work
- Read before you edit. If you have not read a file in this session, read it first.
- Make the smallest change that solves the task. Do not refactor unrelated code.
- Match the surrounding code's style, naming, and imports. Do not invent APIs — check the code or config.
- After editing, run the project's build or tests with Bash when they exist, and report the real result. If something fails, say so and show the output.
- The context window is small. Do not re-read files you already read, do not paste large files back, and do not repeat the user's request. Be brief.

# Replies
- No preamble, no apologies, no flattery. Answer or act.
- When you finish, give a one or two line summary of what changed and how it was verified. Nothing more.
- If the request is ambiguous in a way that changes the result, ask one short question before acting.
```

- [ ] **Step 2: Verify it exists and is reasonably small**

Run: `wc -w conf/ai/llmm/prompts/lean-coder.md`
Expected: a word count greater than 0 and comfortably under 700 words (the Task 3 test enforces `< 700`).

- [ ] **Step 3: Commit**

```bash
git add conf/ai/llmm/prompts/lean-coder.md
git commit   # subject e.g. "Add lean Qwen coder system prompt"
```

---

### Task 3: Lean rewrite of `claude::launch` (+ `assert_not_contains` harness helper)

Rewrite `claude::launch` to take leanness + effective ctx, build `cenv`/`cargs`, validate config loudly, and `exec` — with an `LLMM_DRYRUN` hook that prints the assembled env/args for testing. Add the `assert_not_contains` helper the new tests need.

**Files:**
- Modify: `conf/ai/llmm/tests/harness.zsh` (add `assert_not_contains` after `assert_contains`, ~line 24)
- Modify: `conf/ai/llmm/lib/claude.zsh` (full rewrite)
- Test: `conf/ai/llmm/tests/test_claude.zsh` (create)

- [ ] **Step 1: Add the `assert_not_contains` harness helper**

In `conf/ai/llmm/tests/harness.zsh`, add immediately after the `assert_contains` function (after line 24):

```zsh
assert_not_contains() {  # assert_not_contains <haystack> <needle> [label]
  (( _tests++ ))
  if [[ "$1" == *"$2"* ]]; then
    print -u2 "FAIL ${3:-assert_not_contains}: [$1] unexpectedly contains [$2]"
    (( _fails++ ))
  fi
}
```

- [ ] **Step 2: Write the failing test**

Create `conf/ai/llmm/tests/test_claude.zsh`:

```zsh
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
```

- [ ] **Step 3: Run the suite to verify the new tests fail**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: FAIL — the lean assertions fail because the current `claude::launch` ignores leanness/ctx and has the old 2-arg signature (it will treat `1`/`65536` as extra claude args).

- [ ] **Step 4: Rewrite `claude.zsh`**

Replace the entire contents of `conf/ai/llmm/lib/claude.zsh` with:

```zsh
#!/usr/bin/env zsh
# claude.zsh — launch Claude Code pointed at the local server.
# Two modes:
#   full — today's behavior (default system prompt, all tools, all MCP).
#   lean — minimal session for a weak local model: no MCP, trimmed tools, --bare,
#          a slim replacement system prompt, and a context window the size of the
#          real local window so auto-compaction triggers before the server overflows.

# Built-in tools kept in lean mode (the irreducible coding core).
typeset -ga CLAUDE_LEAN_TOOLS=(Bash Read Edit Write Grep Glob TodoWrite)

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
    local prompt="$(claude::lean_prompt)"
    local pct="$(claude::compact_pct)"
    cenv+=(
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
```

Note: `claude::lean_prompt`/`claude::compact_pct` are evaluated via `$(…)` subshells inside `claude::launch`; when they hit `ui::die` (`exit 1`), the subshell exits empty, the captured value is empty, and the failing test's outer subshell records rc 1. The validation assertions in Step 2 wrap the whole call in `( … )` so the harness shell is never killed.

- [ ] **Step 5: Run the suite to verify it passes**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: PASS — `ran N assertions, 0 failure(s)`.

- [ ] **Step 6: Commit**

```bash
git add conf/ai/llmm/lib/claude.zsh conf/ai/llmm/tests/harness.zsh conf/ai/llmm/tests/test_claude.zsh
git commit   # subject e.g. "Add lean Claude Code launch mode to claude::launch"
```

---

### Task 4: Dispatcher flags (`--lean` / `--full` / `--ctx N`), `start_path`, usage

Wire the new flags into the dispatcher: resolve leanness (`--lean`/`--full` > `LLMM_LEAN` > default 1) and the per-launch ctx override (`--ctx N`), pass both down to `claude::launch`, and document them in usage.

**Files:**
- Modify: `conf/ai/llmm/llmm` (`llmm::usage` ~lines 17-31; `llmm::start_path` lines 33-52; `llmm::route` lines 75-96)
- Test: `conf/ai/llmm/tests/test_config.zsh` (update the existing `_test_llmm_dispatch`, lines 45-62)

- [ ] **Step 1: Update the failing dispatcher test**

In `conf/ai/llmm/tests/test_config.zsh`, replace the `claude::launch` stub and the assertions inside `_test_llmm_dispatch`. Change the stub at line 54 from `claude::launch() { print "launch:$1:$2"; }` to one that echoes leanness and ctx, and add propagation assertions. The function body (lines 53-60) becomes:

```zsh
  # Stub side-effecting deps.
  server::ensure() { print "ensure:$1:$2:$3:$4"; }
  claude::launch() { print "launch:$1:$2:$3:$4"; }   # alias:port:lean:ctx
  models::pick()   { print "/picked/model-Q3_K_M.gguf"; }
  config::load()   { :; }
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
```

(Each `$(llmm::route …)` runs in its own subshell, so the `--ctx` call's `export LLMM_CTX_OVERRIDE` does not leak into later assertions.)

- [ ] **Step 2: Run the suite to verify it fails**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: FAIL — the launch line shows the old 2-field form (`launch:m:11111`), and `--lean`/`--full`/`--ctx` are not parsed.

- [ ] **Step 3: Update `llmm::start_path` to take leanness and pass ctx**

In `conf/ai/llmm/llmm`, replace `llmm::start_path` (lines 33-52) with:

```zsh
llmm::start_path() {  # <profile> <lean> [extra claude args...]
  local profile="$1" lean="$2"; shift 2
  local model="$LLMM_MODEL"
  if [[ -n "${LLMM_PICK:-}" ]]; then
    model="$(models::pick)" || exit 1
  fi
  # Alias is always derived from the model (Qwen3-Coder-Next-UD-Q3_K_M form).
  local alias="$(models::alias_for "$model")"
  # Effective window: --ctx override (via LLMM_CTX_OVERRIDE) or the profile's ctx_size.
  local ctx="$(config::ctx_size "$profile")"
  if [[ -n "${SERVE_ONLY:-}" ]]; then
    server::ensure "$profile" "$model" "$alias" "$LLMM_PORT" || exit 1
    ui::info "SERVE_ONLY set — not launching claude"; exec tail -f /dev/null
  fi
  server::ensure "$profile" "$model" "$alias" "$LLMM_PORT" || exit 1
  # Adopt the actually-running server's alias so Claude's label matches what is
  # loaded — e.g. when ensure reused an existing server with a different model
  # (declined restart). Foreign servers have no meta; keep the derived alias.
  local running_alias="$(server::meta_get "$LLMM_PORT" alias 2>/dev/null)"
  [[ -n "$running_alias" ]] && alias="$running_alias"
  claude::launch "$alias" "$LLMM_PORT" "$lean" "$ctx" "$@"
}
```

- [ ] **Step 4: Update `llmm::route` to parse the new flags**

In `conf/ai/llmm/llmm`, replace the flag-parsing preamble and start-path call sites in `llmm::route` (lines 75-96) with:

```zsh
# llmm::route <command> [args...] — pure routing; returns rc 2 on unknown command.
llmm::route() {
  local cmd="${1:-}"; [[ $# -gt 0 ]] && shift
  # Start-path flags may follow the command. --ctx consumes the next token.
  local profile=default
  local lean="${LLMM_LEAN:-1}"
  local -a rest=()
  local -a args=("$@")
  local i=1
  while (( i <= ${#args} )); do
    case "${args[i]}" in
      --minimal) profile=minimal ;;
      --lean)    lean=1 ;;
      --full)    lean=0 ;;
      --ctx)
        if (( i + 1 > ${#args} )); then ui::die "--ctx requires a value"; fi
        LLMM_CTX_OVERRIDE="${args[i+1]}"; (( i++ )) ;;
      *)         rest+=("${args[i]}") ;;
    esac
    (( i++ ))
  done
  if [[ -n "${LLMM_CTX_OVERRIDE:-}" ]]; then
    [[ "$LLMM_CTX_OVERRIDE" == <-> ]] || ui::die "--ctx requires a positive integer, got: $LLMM_CTX_OVERRIDE"
    export LLMM_CTX_OVERRIDE
  fi

  case "$cmd" in
    ''|start)      llmm::start_path "$profile" "$lean" "${rest[@]}" ;;
    pick)          LLMM_PICK=1 llmm::start_path "$profile" "$lean" "${rest[@]}" ;;
    pull)          models::pull "${rest[1]:-}" ;;
    status|stat|stats) status::report ;;
    logs)          llmm::cmd_logs "${rest[@]}" ;;
    config)        llmm::cmd_config ;;
    kill)          server::kill "$LLMM_PORT" ;;
    help|-h|--help) llmm::usage ;;
    *)             ui::err "unknown command: $cmd"; llmm::usage; return 2 ;;
  esac
}
```

- [ ] **Step 5: Update `llmm::usage`**

In `conf/ai/llmm/llmm`, replace the here-doc body of `llmm::usage` (lines 18-30) with:

```zsh
  cat >&2 <<'EOF'
usage: llmm [command] [flags]

  (no command)        start default model, launch Claude Code
  pick                pick a model, then start + launch
  pull <repo[:quant]> download a model into the dedicated store
  status | stat | stats   show server + hardware stats
  logs [-f] [--tail N]    tail the server log (default --tail 100)
  config              open the config in $EDITOR
  kill                stop the running server
  help                show this help

start-path flags:
  --minimal           use the minimal server profile (small ctx, no warmup)
  --lean | --full     lean Claude Code session (default) or full session
  --ctx N             override the context window for this launch (e.g. 81920)
EOF
```

- [ ] **Step 6: Run the suite to verify it passes**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: PASS — `ran N assertions, 0 failure(s)`.

- [ ] **Step 7: Smoke the dispatcher in library mode (no server needed)**

Run:
```bash
LLMM_NO_MAIN=1 zsh -c 'source conf/ai/llmm/llmm; llmm::usage' 2>&1 | grep -E -- '--lean|--ctx'
```
Expected: the two new usage lines print.

- [ ] **Step 8: Commit**

```bash
git add conf/ai/llmm/llmm conf/ai/llmm/tests/test_config.zsh
git commit   # subject e.g. "Wire --lean/--full/--ctx dispatcher flags into claude::launch"
```

---

### Task 5: Seed the new config keys

Add the four new `LLMM_*` knobs to the shipped default config, with comments, so a fresh `config::seed` documents them. Existing user configs are untouched (seed only copies when absent); env precedence already handles the new scalars.

**Files:**
- Modify: `conf/ai/llmm/config.default.zsh`
- Test: `conf/ai/llmm/tests/test_config.zsh` (append at end)

- [ ] **Step 1: Write the failing test**

Append to the end of `conf/ai/llmm/tests/test_config.zsh`:

```zsh
# Shipped defaults parse under no_unset and define the lean knobs.
assert_eq "$( source "$LLMM_ROOT/config.default.zsh"; print -r -- "${LLMM_LEAN}" )" 1 "default LLMM_LEAN=1"
assert_eq "$( source "$LLMM_ROOT/config.default.zsh"; print -r -- "${LLMM_COMPACT_PCT}" )" 80 "default LLMM_COMPACT_PCT=80"
```

- [ ] **Step 2: Run the suite to verify it fails**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: FAIL — `LLMM_LEAN`/`LLMM_COMPACT_PCT` unset (with `set -u`, the `$( source … )` subshell errors / prints empty), assertions fail.

- [ ] **Step 3: Add the keys to the default config**

In `conf/ai/llmm/config.default.zsh`, insert after the `LLMM_LOG_MAX_MIB` line (line 6) and before the alias comment block (line 8):

```zsh

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
```

- [ ] **Step 4: Run the suite to verify it passes**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: PASS — `ran N assertions, 0 failure(s)`.

- [ ] **Step 5: Commit**

```bash
git add conf/ai/llmm/config.default.zsh conf/ai/llmm/tests/test_config.zsh
git commit   # subject e.g. "Seed lean config knobs in config.default.zsh"
```

---

### Task 6: Documentation (`conf/ai/README.md`)

Document the lean/full profiles, the new config knobs, the `--ctx` flag, the MCP opt-in, and a before/after token-budget note. (`conf/ai/README.md` is the project's Markdown landing page for this area — it stays Markdown.)

**Files:**
- Modify: `conf/ai/README.md` (the `## llmm` section — `### Commands`, `### Config & storage`, `### Tests`)

- [ ] **Step 1: Add a lean/full subsection and the `--ctx` command**

In `conf/ai/README.md`, in the `### Commands` list under `## llmm`, add these entries after the `llmm [pick] --minimal` line:

```markdown
- `llmm [pick] --full` — full Claude Code session (default is **lean**: no MCP,
  trimmed tools, `--bare`, a slim Qwen-tuned system prompt, and a context window
  matched to the real local window). `--lean` forces lean explicitly.
- `llmm [pick] --ctx N` — override the context window for this launch (e.g.
  `--ctx 81920` for ~80K). Feeds both llama-server's `--ctx-size` and Claude
  Code's `CLAUDE_CODE_AUTO_COMPACT_WINDOW`.
```

- [ ] **Step 2: Document the new config knobs**

In `conf/ai/README.md`, in the `### Config & storage` bullet that describes the config file, append after the profiles sentence:

```markdown
  Lean-mode knobs: `LLMM_LEAN` (1 = lean by default), `LLMM_MCP_CONFIG` (path to a
  minimal MCP json to re-admit servers like context7 under lean; empty = none),
  `LLMM_SYSTEM_PROMPT` (replacement prompt path; empty = shipped
  `prompts/lean-coder.md`), and `LLMM_COMPACT_PCT` (auto-compact threshold %,
  default 80). The effective context window is `--ctx N` > the active profile's
  `ctx_size`; Claude Code is told that same window so auto-compaction triggers
  before the local server overflows (it otherwise assumes 200K for custom
  endpoints).
```

- [ ] **Step 3: Add a token-budget note**

In `conf/ai/README.md`, add this paragraph at the end of the `## llmm` section (after the v1.1 note):

```markdown
### Why lean

A local model's context window is small (≈32–64K on a 48 GB Mac for
Qwen3-Coder-Next), but Claude Code's fixed overhead — built-in tools (~24K), MCP
tool schemas (~17K), system prompt (~3–4K), memory (~4.5K), skills (~4K) — can eat
~50K of it before any work begins. Compaction only reclaims conversation tokens,
not this fixed overhead, so the fix is to cut the overhead: lean mode recovers
roughly 35–40K, leaving the window for actual code. Note 32K is the safe ctx floor
on 48 GB; raise `default.ctx_size` (or use `--ctx`) on machines with more RAM.
```

- [ ] **Step 4: Update the Tests description**

In `conf/ai/README.md`, in the `### Tests` paragraph, update the parenthetical list of what the suite covers to include the new coverage. Replace the existing parenthetical with:

```markdown
(pure helpers: config precedence, effective window resolution, model
labels/discovery/alias derivation, arg building, meta round-trip, log rotation,
dispatcher routing, and lean/full launch-arg assembly).
```

- [ ] **Step 5: Commit**

```bash
git add conf/ai/README.md
git commit   # subject e.g. "Document lean/full profiles and --ctx in conf/ai README"
```

---

### Task 7: Verify-first smoke (env-var names + lean budget) — MANUAL

The two compaction env-var names are doc-sourced, not yet confirmed. This task confirms them empirically against a live server and records the real token budget. It is manual (needs a running model) and has a fallback path if a name is wrong.

**Files:**
- Modify (only if findings require it): `conf/ai/llmm/lib/claude.zsh`, `conf/ai/README.md`

- [ ] **Step 1: Launch a lean session against the live server**

Run: `llmm` (lean is default). Wait for Claude Code to open.

- [ ] **Step 2: Confirm the window is read as the local size, not 200K**

In the session, run `/context`. 
Expected: the meter denominator reflects the local window (e.g. `/64K` or `/65536`), NOT `/200K`, and fixed overhead (system + tools + MCP + memory) reads roughly **10–13K**, not ~50K.
- If it shows `/200K`: `CLAUDE_CODE_AUTO_COMPACT_WINDOW` is the wrong name. Check `claude --help`, the env-vars doc (`https://code.claude.com/docs/en/env-vars.md`), or test candidates, find the correct variable, update the `cenv+=( … )` block in `conf/ai/llmm/lib/claude.zsh`, and re-run the unit suite.

- [ ] **Step 3: Confirm auto-compaction triggers near the threshold**

Drive the session until usage approaches `LLMM_COMPACT_PCT`% of the window (or temporarily set `LLMM_COMPACT_PCT` low, e.g. `LLMM_COMPACT_PCT=40 llmm`, and do a few file reads).
Expected: auto-compaction fires near the threshold rather than overflowing the local server.
- If it never fires: `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` is likely wrong — same fallback as Step 2.

- [ ] **Step 4: Confirm tool-calling still works under `--bare` + replacement prompt**

Ask the lean session to read a file and make a small edit.
Expected: the model successfully calls Read then Edit. (Schemas are independent of the system-prompt text, so this should work; if it does not, note it — it may indicate the slim prompt needs more explicit tool guidance, tunable in `prompts/lean-coder.md`.)

- [ ] **Step 5: Confirm `--ctx` experiment path**

Run: `llmm --ctx 81920` and re-check `/context`.
Expected: the window now reads ~80K (and the server restarts if one was running at a different ctx). If the machine can't hold it, llama-server fails loudly in the logs (`llmm logs`) — that is the expected failure mode, not a bug.

- [ ] **Step 6: Record the real before/after numbers**

Update the "Why lean" paragraph in `conf/ai/README.md` if the measured overhead differs materially from the ~10–13K / ~50K estimates, replacing the estimates with the observed figures.

- [ ] **Step 7: Commit any findings-driven changes**

```bash
git add -A
git commit   # subject e.g. "Confirm/fix lean window env vars from live smoke" (skip if no changes)
```

---

## Self-Review

**Spec coverage:**
- Profile model (lean default, `--lean`/`--full`) → Task 4. ✓
- Lean flag set (`--bare`, `--strict-mcp-config`, `--tools`, `--system-prompt-file`) → Task 3. ✓
- MCP dropped + `LLMM_MCP_CONFIG` opt-in → Task 3 (build + tests). ✓
- Slim Qwen prompt + `LLMM_SYSTEM_PROMPT` override → Tasks 2 & 3. ✓
- Window awareness `CLAUDE_CODE_AUTO_COMPACT_WINDOW` from effective ctx → Tasks 1, 3, 4. ✓
- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` / `LLMM_COMPACT_PCT` (default 80, validated) → Task 3. ✓
- Window sizing: configurable default + `--ctx N` override, lock-step → Tasks 1, 4. ✓
- Restart semantics on ctx change → relies on existing `server::ensure` (meta records ctx via Task 1); no new code needed. ✓
- Loud validation (missing prompt/mcp file, bad pct, bad `--ctx`) → Tasks 3 & 4. ✓
- Config seeding → Task 5. ✓
- Unit tests (lean/full argv, overrides, validation, dispatcher propagation, ctx resolution) → Tasks 1, 3, 4, 5. ✓
- Manual smoke / verify-first env names → Task 7. ✓
- Docs → Task 6. ✓
- Roadmap `Later` (per-model prompt selection; 32K floor note): captured in the docs "Why lean" note (32K floor) and spec; no separate task needed.

**Placeholder scan:** No TBD/TODO; every code step shows full code; commands have expected output. ✓

**Type/name consistency:** `config::ctx_size`, `claude::launch <alias> <port> <lean> <ctx> …`, `CLAUDE_LEAN_TOOLS`, `claude::lean_prompt`, `claude::compact_pct`, `LLMM_CTX_OVERRIDE`, `LLMM_LEAN`, `LLMM_MCP_CONFIG`, `LLMM_SYSTEM_PROMPT`, `LLMM_COMPACT_PCT`, `LLMM_DRYRUN` used consistently across Tasks 1, 3, 4, 5. The launch stub in the Task 4 test prints `alias:port:lean:ctx` matching the real 4-arg signature. ✓
