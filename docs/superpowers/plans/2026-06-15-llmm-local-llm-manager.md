# llmm — Local-LLM Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `conf/ai/lcpp.claude` with `llmm` — a zsh-based local-LLM server manager + Claude Code launcher, plus a bash build/deps installer, wired into `evn install llmm`.

**Architecture:** A thin `llmm` zsh dispatcher (symlinked onto PATH) resolves its own repo path via `${0:A}` and sources focused `lib/*.zsh` units (config, models, server, status, claude, ui). A separate bash (3.2-safe) `install.sh` builds llama.cpp from source into an XDG-local prefix, installs deps (uv + huggingface CLI), and seeds config. Runtime state (per-port `.meta` + rotated logs) lives under `$XDG_STATE_HOME/llmm`; models live under `$XDG_DATA_HOME/llmm/models` (`HF_HOME`).

**Tech Stack:** zsh 5.x (tool), bash 3.2-safe (installer), llama.cpp (`llama-server`), `uv` + `huggingface_hub[cli]`, `fzf` (optional), `curl`. Tests: self-contained zsh assertion harness + `zsh -n`/`bash -n`.

**Spec:** `docs/superpowers/specs/2026-06-15-llmm-local-llm-manager-design.md`

---

## File Structure

```
conf/ai/llmm/                  # == future standalone repo root
  llmm                         # dispatcher (symlinked to ~/.local/bin/llmm)
  install.sh                   # bash 3.2-safe build + deps installer
  config.default.zsh           # seeded into ~/.config/llmm/config.zsh
  lib/
    ui.zsh                     # color/log helpers, numbered menu, fzf wrapper
    config.zsh                 # locate/seed/source config; env precedence; profile lookup
    models.zsh                 # discover + label + pick + pull
    server.zsh                 # bin resolve, health, log rotation, start, kill, meta
    status.zsh                 # system mem + parse server log + report
    claude.zsh                 # exec claude with ANTHROPIC_* env
  tests/
    harness.zsh                # assert helpers + runner
    test_config.zsh
    test_models.zsh
    test_server.zsh
    test_status.zsh
    fixtures/                  # fake HF hub + model tree, sample server log
_impl/install.bash4            # + install::llmm_settings (shim)
_impl/control.sh               # + llmm) case, update trigger, help, modulecheck
.update-list                   # + llmm:<0|1>
```

**Conventions for all zsh files:** start with `emulate -L zsh` inside functions where option safety matters; libs assume the dispatcher has set globals `LLMM_ROOT` (repo dir), and the loaded config. Functions are namespaced `unit::fn`. Errors go through `ui::die`. No `set -e` in zsh libs (zsh's error semantics differ); guard explicitly.

---

## Stage 1 — Test harness

### Task 1: Self-contained zsh assertion harness

**Files:**
- Create: `conf/ai/llmm/tests/harness.zsh`

- [ ] **Step 1: Write the harness**

```zsh
#!/usr/bin/env zsh
# Minimal self-contained test harness. Usage:
#   zsh tests/harness.zsh           # runs every tests/test_*.zsh
# Each test_*.zsh sources libs from $LLMM_LIB and calls assert_* helpers.
emulate -L zsh
set -u

typeset -g _tests=0 _fails=0

assert_eq() {  # assert_eq <got> <want> [label]
  (( _tests++ ))
  if [[ "$1" != "$2" ]]; then
    print -u2 "FAIL ${3:-assert_eq}: got [$1] want [$2]"
    (( _fails++ ))
  fi
}

assert_contains() {  # assert_contains <haystack> <needle> [label]
  (( _tests++ ))
  if [[ "$1" != *"$2"* ]]; then
    print -u2 "FAIL ${3:-assert_contains}: [$1] does not contain [$2]"
    (( _fails++ ))
  fi
}

assert_rc() {  # assert_rc <expected_rc> <actual_rc> [label]
  (( _tests++ ))
  if [[ "$1" != "$2" ]]; then
    print -u2 "FAIL ${3:-assert_rc}: expected rc $1 got $2"
    (( _fails++ ))
  fi
}

typeset -g LLMM_TESTS_DIR="${0:A:h}"
typeset -g LLMM_ROOT="${LLMM_TESTS_DIR:h}"
typeset -g LLMM_LIB="$LLMM_ROOT/lib"

for _t in "$LLMM_TESTS_DIR"/test_*.zsh(N); do
  source "$_t"
done

print "ran $_tests assertions, $_fails failure(s)"
(( _fails == 0 ))
```

- [ ] **Step 2: Verify it runs green with no tests**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: `ran 0 assertions, 0 failure(s)` and exit 0.

- [ ] **Step 3: Commit**

```bash
git add conf/ai/llmm/tests/harness.zsh
git commit -m "test(llmm): add self-contained zsh assertion harness"
```

---

## Stage 2 — Library units (zsh)

### Task 2: `lib/ui.zsh` — logging, menu, fzf wrapper

**Files:**
- Create: `conf/ai/llmm/lib/ui.zsh`
- Test: `conf/ai/llmm/tests/test_config.zsh` (shared file; ui asserts added here)

- [ ] **Step 1: Write failing test for `ui::menu` selection**

Append to `conf/ai/llmm/tests/test_config.zsh` (create the file):

```zsh
source "$LLMM_LIB/ui.zsh"

# ui::pick_index maps a 1-based choice string to a 0-based index, or -1 if invalid.
assert_eq "$(ui::pick_index 3 5)" 2 "ui::pick_index valid"
assert_eq "$(ui::pick_index 0 5)" -1 "ui::pick_index too-low"
assert_eq "$(ui::pick_index 6 5)" -1 "ui::pick_index too-high"
assert_eq "$(ui::pick_index abc 5)" -1 "ui::pick_index non-numeric"
assert_eq "$(ui::pick_index '' 5)" -1 "ui::pick_index empty"
```

- [ ] **Step 2: Run to verify it fails**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: FAIL lines for `ui::pick_index` (command not found / wrong output).

- [ ] **Step 3: Implement `lib/ui.zsh`**

```zsh
#!/usr/bin/env zsh
# ui.zsh — user-facing output + simple selection. No side effects on source.

typeset -g UI_RED=$'\e[31m' UI_YEL=$'\e[33m' UI_GRN=$'\e[32m' UI_DIM=$'\e[2m' UI_RST=$'\e[0m'
[[ -t 2 ]] || { UI_RED= UI_YEL= UI_GRN= UI_DIM= UI_RST= }

ui::info() { print -r -- "${UI_GRN}==>${UI_RST} $*"; }
ui::warn() { print -u2 -r -- "${UI_YEL}war: ${UI_RST}$*"; }
ui::err()  { print -u2 -r -- "${UI_RED}error: ${UI_RST}$*"; }
ui::die()  { ui::err "$*"; exit 1; }

ui::has() { command -v "$1" &>/dev/null; }

# ui::pick_index <choice> <count> -> echoes 0-based index, or -1 if invalid.
ui::pick_index() {
  local choice="$1" count="$2"
  if [[ "$choice" != <-> ]]; then print -- -1; return; fi   # <-> = zsh integer glob
  if (( choice < 1 || choice > count )); then print -- -1; return; fi
  print -- $(( choice - 1 ))
}

# ui::menu <prompt> <item...> -> echoes the chosen item to stdout, or rc 1 on abort.
ui::menu() {
  local prompt="$1"; shift
  local -a items=("$@")
  local i
  for (( i = 1; i <= $#items; i++ )); do
    print -u2 -r -- "  $i) ${items[i]}"
  done
  local choice idx
  print -u2 -n -- "$prompt [1-$#items]: "
  read -r choice
  idx=$(ui::pick_index "$choice" $#items)
  if [[ "$idx" == -1 ]]; then ui::err "invalid selection: '$choice'"; return 1; fi
  print -r -- "${items[idx + 1]}"
}
```

- [ ] **Step 4: Run to verify pass**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: the 5 `ui::pick_index` assertions pass.

- [ ] **Step 5: Commit**

```bash
git add conf/ai/llmm/lib/ui.zsh conf/ai/llmm/tests/test_config.zsh
git commit -m "feat(llmm): ui helpers (log, menu, index validation)"
```

---

### Task 3: `lib/config.zsh` — XDG paths, env precedence, profile lookup

**Files:**
- Create: `conf/ai/llmm/lib/config.zsh`
- Create: `conf/ai/llmm/config.default.zsh`
- Test: `conf/ai/llmm/tests/test_config.zsh`

- [ ] **Step 1: Write failing tests for profile lookup + env precedence**

Append to `conf/ai/llmm/tests/test_config.zsh`:

```zsh
source "$LLMM_LIB/config.zsh"

# Profile lookup reads dotted keys from LLMM_PROFILES.
typeset -gA LLMM_PROFILES=( default.ctx_size 65536  minimal.ctx_size 16384  minimal.warmup 0 )
assert_eq "$(config::pf default ctx_size)" 65536 "pf default"
assert_eq "$(config::pf minimal ctx_size)" 16384 "pf minimal"
assert_eq "$(config::pf minimal warmup)" 0 "pf minimal warmup"

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
```

- [ ] **Step 2: Run to verify fail**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: FAIL on `config::pf`, `config::data_dir`, `config::load` (undefined).

- [ ] **Step 3: Implement `lib/config.zsh`**

```zsh
#!/usr/bin/env zsh
# config.zsh — locate/seed/source config, env precedence, profile + dir lookup.

config::reset_dirs() { :; }  # placeholder so callers can force re-eval; dirs are computed live.

config::config_home() { print -r -- "${XDG_CONFIG_HOME:-$HOME/.config}"; }
config::data_dir()    { print -r -- "${XDG_DATA_HOME:-$HOME/.local/share}/llmm"; }
config::state_dir()   { print -r -- "${XDG_STATE_HOME:-$HOME/.local/state}/llmm"; }
config::models_dir()  { print -r -- "$(config::data_dir)/models"; }
config::bin_dir()     { print -r -- "$(config::data_dir)/bin"; }
config::file()        { print -r -- "$(config::config_home)/llmm/config.zsh"; }

# config::pf <profile> <field> -> echoes LLMM_PROFILES[profile.field]
config::pf() { print -r -- "${LLMM_PROFILES[$1.$2]-}"; }

# config::seed -> copy the shipped default into the user config if absent.
config::seed() {
  local dst="$(config::file)" src="$LLMM_ROOT/config.default.zsh"
  [[ -f "$dst" ]] && return 0
  mkdir -p "${dst:h}"
  cp "$src" "$dst"
  ui::info "seeded config at $dst"
}

# config::load [path] -> source config with env vars taking precedence.
# Captures already-set LLMM_* env, sources the file, then re-applies the captures.
config::load() {
  local cfg="${1:-$(config::file)}"
  typeset -A _pre
  local v
  for v in ${(k)parameters[(I)LLMM_*]}; do
    # Only snapshot scalar env overrides; skip arrays/associations (e.g. LLMM_PROFILES),
    # which the config file owns and which can't round-trip through a scalar capture.
    [[ ${parameters[$v]} == *association* || ${parameters[$v]} == *array* ]] && continue
    _pre[$v]="${(P)v}"
  done
  [[ -f "$cfg" ]] && source "$cfg"
  for v in ${(k)_pre}; do typeset -g "$v"="${_pre[$v]}"; done
}
```

Note: `${(k)parameters[(I)LLMM_*]}` lists currently-set parameter names matching `LLMM_*`; `${(P)v}` dereferences; `${parameters[$v]}` gives the type, so arrays/associations like `LLMM_PROFILES` are skipped (they can't round-trip through a scalar capture). This captures scalar env overrides before sourcing and restores them after.

- [ ] **Step 4: Write `config.default.zsh`**

```zsh
# llmm configuration — sourced by the llmm dispatcher (zsh).
# Precedence: env LLMM_* > this file > built-in defaults.

LLMM_PORT=${LLMM_PORT:-11111}
LLMM_MODEL=${LLMM_MODEL:-'unsloth/Qwen3-Coder-Next-GGUF:UD-Q3_K_M'}
LLMM_ALIAS=${LLMM_ALIAS:-qwen3-coder-next}
LLMM_LOG_MAX_MIB=${LLMM_LOG_MAX_MIB:-50}   # rotate the server log past this size

# mmap: 0 = --no-mmap (load weights into RAM up front). Default 0 on macOS:
#   predictable RSS, no mid-generation page-in stalls, and avoids the Metal
#   warmup-time allocation OOM. Set 1 to memory-map (lazy, lower apparent RAM,
#   evictable under pressure) when a model barely fits.
typeset -gA LLMM_PROFILES=(
  default.ctx_size 65536  default.gpu_layers auto  default.flash_attn on  default.warmup 1  default.mmap 0
  minimal.ctx_size 16384  minimal.gpu_layers auto  minimal.flash_attn on  minimal.warmup 0  minimal.mmap 0
)
```

- [ ] **Step 5: Run to verify pass**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: all config assertions pass.

- [ ] **Step 6: Commit**

```bash
git add conf/ai/llmm/lib/config.zsh conf/ai/llmm/config.default.zsh conf/ai/llmm/tests/test_config.zsh
git commit -m "feat(llmm): config loader (XDG dirs, env precedence, profiles)"
```

---

### Task 4: `lib/models.zsh` — discover, label, pick, pull

**Files:**
- Create: `conf/ai/llmm/lib/models.zsh`
- Create: `conf/ai/llmm/tests/test_models.zsh`
- Create fixtures under `conf/ai/llmm/tests/fixtures/`

- [ ] **Step 1: Write failing tests for `models::label` and `models::discover`**

Create `conf/ai/llmm/tests/test_models.zsh`:

```zsh
source "$LLMM_LIB/ui.zsh"
source "$LLMM_LIB/config.zsh"
source "$LLMM_LIB/models.zsh"

# Label: HF-cache path -> "[hf] org/repo  file.gguf"; split org--repo on FIRST '--'.
hf="/x/huggingface/hub/models--unsloth--Qwen3-Coder-Next-GGUF/snapshots/abc/model-Q3.gguf"
assert_contains "$(models::label "$hf")" "[hf]" "label hf tag"
assert_contains "$(models::label "$hf")" "unsloth/Qwen3-Coder-Next-GGUF" "label hf repo"
assert_contains "$(models::label "$hf")" "model-Q3.gguf" "label hf file"

# Repo name that itself contains '--' must only split on the first one.
hf2="/x/huggingface/hub/models--meta-llama--Meta-Llama-3--8B/snapshots/d/m.gguf"
assert_contains "$(models::label "$hf2")" "meta-llama/Meta-Llama-3--8B" "label hf double-dash"

# Local path -> "[local] file.gguf"
assert_contains "$(models::label /opt/models/foo.gguf)" "[local] foo.gguf" "label local"

# Discover finds the symlinked .gguf inside the fixture HF hub (find -L).
fx="$LLMM_TESTS_DIR/fixtures"
out="$(LLMM_DISCOVER_DIRS=("$fx/models" "$fx/hub") models::discover)"
assert_contains "$out" "tiny-Q3_K_M.gguf" "discover local"
assert_contains "$out" "fixture-model.gguf" "discover hf symlink"
```

- [ ] **Step 2: Create fixtures**

```bash
mkdir -p conf/ai/llmm/tests/fixtures/models
mkdir -p "conf/ai/llmm/tests/fixtures/hub/models--org--fixture/blobs"
mkdir -p "conf/ai/llmm/tests/fixtures/hub/models--org--fixture/snapshots/deadbeef"
: > conf/ai/llmm/tests/fixtures/models/tiny-Q3_K_M.gguf
echo "blob" > "conf/ai/llmm/tests/fixtures/hub/models--org--fixture/blobs/sha123"
ln -sf ../../blobs/sha123 \
  "conf/ai/llmm/tests/fixtures/hub/models--org--fixture/snapshots/deadbeef/fixture-model.gguf"
```

- [ ] **Step 3: Run to verify fail**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: FAIL on `models::label` / `models::discover` (undefined).

- [ ] **Step 4: Implement `lib/models.zsh`**

```zsh
#!/usr/bin/env zsh
# models.zsh — discover local + HF-cache GGUFs, format labels, pick, pull.

# models::label <path> -> human label. HF-cache paths render as "[hf] org/repo  file".
models::label() {
  local f="$1"
  if [[ "$f" == */huggingface/hub/models--* || "$f" == */llmm/models/*models--* ]]; then
    local dir org rest
    dir="${f##*/models--}"; dir="${dir%%/*}"   # e.g. org--repo--with--dashes
    org="${dir%%--*}"                            # first segment
    rest="${dir#*--}"                            # remainder, dashes intact
    printf '[hf]    %-50s  %s' "$org/$rest" "${f:t}"
  else
    printf '[local] %s' "${f:t}"
  fi
}

# models::discover -> one absolute path per line, sorted+unique.
# Search dirs: models dir, legacy state models dir, default HF hub. Overridable
# for tests via LLMM_DISCOVER_DIRS array.
models::discover() {
  local -a dirs
  if (( ${+LLMM_DISCOVER_DIRS} )); then
    dirs=("${LLMM_DISCOVER_DIRS[@]}")
  else
    dirs=(
      "$(config::models_dir)"
      "${XDG_STATE_HOME:-$HOME/.local/state}/models"
      "${XDG_CACHE_HOME:-$HOME/.cache}/huggingface/hub"
    )
  fi
  local d
  for d in "${dirs[@]}"; do
    [[ -d "$d" ]] || continue
    # -L dereferences the snapshots/*.gguf symlinks the HF hub uses.
    find -L "$d" -maxdepth 6 -name '*.gguf' -type f 2>/dev/null
  done | sort -u
}

# models::pick -> echoes a chosen model path, rc 1 on abort/none.
models::pick() {
  local -a models
  models=("${(@f)$(models::discover)}")
  if (( ${#models} == 0 )) || [[ -z "${models[1]}" ]]; then
    ui::err "no .gguf models found"; return 1
  fi
  if ui::has fzf; then
    local sel
    sel=$(
      local m
      for m in "${models[@]}"; do printf '%s\t%s\n' "$(models::label "$m")" "$m"; done \
        | fzf --prompt='pick model: ' --no-sort --with-nth=1 --delimiter=$'\t' \
        | cut -f2
    )
    [[ -n "$sel" ]] || { ui::err "aborted"; return 1; }
    print -r -- "$sel"
  else
    local -a labels
    local m
    for m in "${models[@]}"; do labels+=("$(models::label "$m")") ; done
    local chosen idx
    chosen=$(ui::menu "pick model" "${labels[@]}") || return 1
    # Map chosen label back to its path by index.
    for (( idx = 1; idx <= $#labels; idx++ )); do
      [[ "${labels[idx]}" == "$chosen" ]] && { print -r -- "${models[idx]}"; return 0; }
    done
    return 1
  fi
}

# models::pull <repo[:quant]> -> download into the dedicated dir.
# Primary: hf CLI. Fallback: note that llama-server --hf-repo will fetch on start.
models::pull() {
  local repo="$1"
  [[ -n "$repo" ]] || { ui::err "usage: llmm pull <repo[:quant]>"; return 1; }
  local mdir="$(config::models_dir)"
  mkdir -p "$mdir"
  export HF_HOME="$mdir"
  if ui::has hf; then
    local name="${repo%%:*}" quant="${repo#*:}"
    if [[ "$quant" == "$repo" ]]; then
      ui::info "downloading $name (all files) into $mdir"
      hf download "$name"
    else
      ui::info "downloading $name (*$quant*.gguf) into $mdir"
      hf download "$name" --include "*${quant}*.gguf"
    fi
  else
    ui::warn "hf CLI not found; the server will download '$repo' via --hf-repo on first start (into $mdir)"
    return 0
  fi
}
```

- [ ] **Step 5: Run to verify pass**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: all `models::*` assertions pass.

- [ ] **Step 6: Commit**

```bash
git add conf/ai/llmm/lib/models.zsh conf/ai/llmm/tests/test_models.zsh conf/ai/llmm/tests/fixtures
git commit -m "feat(llmm): model discovery, labels, picker, pull"
```

---

### Task 5: `lib/server.zsh` — bin resolve, health, rotation, start, kill, meta

**Files:**
- Create: `conf/ai/llmm/lib/server.zsh`
- Create: `conf/ai/llmm/tests/test_server.zsh`

- [ ] **Step 1: Write failing tests for pure helpers (meta round-trip, rotation decision, arg build)**

Create `conf/ai/llmm/tests/test_server.zsh`:

```zsh
source "$LLMM_LIB/ui.zsh"
source "$LLMM_LIB/config.zsh"
source "$LLMM_LIB/server.zsh"

typeset -gA LLMM_PROFILES=(
  default.ctx_size 65536 default.gpu_layers auto default.flash_attn on default.warmup 1 default.mmap 0
  minimal.ctx_size 16384 minimal.gpu_layers auto minimal.flash_attn on minimal.warmup 0 minimal.mmap 0
)

# Arg builder: default profile keeps warmup+mmap (no --no-* flags).
args="$(server::build_args default /m.gguf myalias 11111)"
assert_contains "$args" "--ctx-size 65536" "args ctx"
assert_contains "$args" "--alias myalias" "args alias"
assert_contains "$args" "--model /m.gguf" "args local model"
[[ "$args" != *"--no-warmup"* ]] && pass1=ok || pass1=no
assert_eq "$pass1" ok "default keeps warmup"

# minimal profile adds --no-warmup and --no-mmap.
amin="$(server::build_args minimal /m.gguf a 11111)"
assert_contains "$amin" "--no-warmup" "minimal no-warmup"
assert_contains "$amin" "--no-mmap" "minimal no-mmap"
assert_contains "$amin" "--ctx-size 16384" "minimal ctx"

# Remote repo (no leading slash, not a file) uses --hf-repo.
arepo="$(server::build_args default org/repo:Q3 a 11111)"
assert_contains "$arepo" "--hf-repo org/repo:Q3" "args hf-repo"

# Meta round-trip.
tmp="$(mktemp -d)"; XDG_STATE_HOME="$tmp"
server::meta_write 11111 4242 /m.gguf myalias 65536 default
assert_eq "$(server::meta_get 11111 pid)" 4242 "meta pid"
assert_eq "$(server::meta_get 11111 alias)" myalias "meta alias"
assert_eq "$(server::meta_get 11111 profile)" default "meta profile"

# Rotation decision: rotate only when size (MiB) exceeds cap.
assert_eq "$(server::should_rotate 60 50)" yes "rotate over cap"
assert_eq "$(server::should_rotate 10 50)" no  "no rotate under cap"
rm -rf "$tmp"
```

- [ ] **Step 2: Run to verify fail**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: FAIL on undefined `server::*`.

- [ ] **Step 3: Implement `lib/server.zsh`**

```zsh
#!/usr/bin/env zsh
# server.zsh — locate llama-server, manage one server keyed by port.

server::run_dir()  { print -r -- "$(config::state_dir)/run"; }
server::log_dir()  { print -r -- "$(config::state_dir)/log"; }
server::metafile() { print -r -- "$(server::run_dir)/$1.meta"; }
server::logfile()  { print -r -- "$(server::log_dir)/$1.log"; }

# server::resolve_bin -> path to llama-server (built prefix first, then PATH).
server::resolve_bin() {
  local built="$(config::bin_dir)/llama-server"
  if [[ -x "$built" ]]; then print -r -- "$built"; return 0; fi
  command -v llama-server 2>/dev/null && return 0
  return 1
}

# server::lib_dir -> dir to prepend to (DY)LD_LIBRARY_PATH for the launch.
server::lib_dir() {
  local bin; bin="$(server::resolve_bin)" || return 1
  print -r -- "${bin:h}"
}

# server::build_args <profile> <model> <alias> <port> -> prints the llama-server argv (space-joined).
server::build_args() {
  local profile="$1" model="$2" alias="$3" port="$4"
  local -a a
  if [[ -f "$model" ]]; then a+=(--model "$model"); else a+=(--hf-repo "$model"); fi
  a+=(--alias "$alias" --port "$port")
  a+=(--ctx-size "$(config::pf "$profile" ctx_size)")
  a+=(--flash-attn "$(config::pf "$profile" flash_attn)")
  a+=(--jinja)
  a+=(--n-gpu-layers "$(config::pf "$profile" gpu_layers)")
  [[ "$(config::pf "$profile" warmup)" == 0 ]] && a+=(--no-warmup)
  [[ "$(config::pf "$profile" mmap)"   == 0 ]] && a+=(--no-mmap)
  print -r -- "${a[*]}"
}

server::is_healthy() {
  curl -fsS "http://127.0.0.1:$1/health" >/dev/null 2>&1
}

server::meta_write() {  # <port> <pid> <model> <alias> <ctx> <profile>
  local port="$1"; mkdir -p "$(server::run_dir)"
  {
    print -r -- "pid=$2"
    print -r -- "model=$3"
    print -r -- "alias=$4"
    print -r -- "ctx_size=$5"
    print -r -- "profile=$6"
    print -r -- "started_at=$(date +%s)"
    print -r -- "logfile=$(server::logfile "$port")"
  } > "$(server::metafile "$port")"
}

server::meta_get() {  # <port> <key>
  local mf="$(server::metafile "$1")"
  [[ -f "$mf" ]] || return 1
  local line; line="$(grep "^$2=" "$mf" | head -1)"
  print -r -- "${line#*=}"
}

server::meta_clear() { rm -f "$(server::metafile "$1")"; }

# server::should_rotate <size_mib> <cap_mib> -> yes|no
server::should_rotate() { (( $1 > $2 )) && print -- yes || print -- no; }

server::rotate_log() {  # <port>
  local lf="$(server::logfile "$1")"
  [[ -f "$lf" ]] || return 0
  local mib=$(( $(stat -f%z "$lf" 2>/dev/null || stat -c%s "$lf") / 1048576 ))
  if [[ "$(server::should_rotate "$mib" "${LLMM_LOG_MAX_MIB:-50}")" == yes ]]; then
    mv -f "$lf" "$lf.1"
  fi
}

# server::start <profile> <model> <alias> <port> -> launches, waits health, writes meta.
server::start() {
  local profile="$1" model="$2" alias="$3" port="$4"
  local bin; bin="$(server::resolve_bin)" || ui::die "llama-server not found; run: evn install llmm"
  mkdir -p "$(server::run_dir)" "$(server::log_dir)"
  server::rotate_log "$port"
  local lf="$(server::logfile "$port")"
  local libdir="$(server::lib_dir)"
  local -a argv=("${(z)$(server::build_args "$profile" "$model" "$alias" "$port")}")

  ui::info "starting llama-server :$port  model=$model  profile=$profile"
  [[ -f "$model" ]] || ui::info "first run may download the model — this can take several minutes"

  export HF_HOME="$(config::models_dir)" LLAMA_CACHE="$(config::models_dir)"
  if [[ "$(uname)" == Darwin ]]; then
    DYLD_LIBRARY_PATH="$libdir${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" "$bin" "${argv[@]}" >"$lf" 2>&1 &
  else
    LD_LIBRARY_PATH="$libdir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" "$bin" "${argv[@]}" >"$lf" 2>&1 &
  fi
  local pid=$!

  local i
  for (( i = 1; i <= 300; i++ )); do
    if server::is_healthy "$port"; then
      server::meta_write "$port" "$pid" "$model" "$alias" "$(config::pf "$profile" ctx_size)" "$profile"
      ui::info "server ready (pid $pid)"
      return 0
    fi
    if ! kill -0 "$pid" 2>/dev/null; then
      ui::err "llama-server exited during startup. Last log lines:"; tail -20 "$lf" >&2; return 1
    fi
    sleep 2
    (( i % 15 == 0 )) && ui::info "still waiting ($(( i * 2 ))s)..."
  done
  ui::err "llama-server did not become healthy within 600s. Last log lines:"; tail -20 "$lf" >&2
  return 1
}

# server::ensure <profile> <model> <alias> <port> -> reuse healthy or start; handle mismatch.
server::ensure() {
  local profile="$1" model="$2" alias="$3" port="$4"
  if server::is_healthy "$port"; then
    local rmodel="$(server::meta_get "$port" model 2>/dev/null || true)"
    local rprof="$(server::meta_get "$port" profile 2>/dev/null || true)"
    if [[ -z "$rmodel" ]]; then
      ui::warn "a foreign server is healthy on :$port (not started by llmm); reusing it"
      return 0
    fi
    if [[ "$rmodel" == "$model" && "$rprof" == "$profile" ]]; then
      ui::info "reusing running server :$port"
      return 0
    fi
    if [[ -t 0 ]]; then
      print -u2 -n "running server has model=$rmodel profile=$rprof; restart with new config? [y/N] "
      local ans; read -r ans
      if [[ "$ans" == [yY]* ]]; then server::kill "$port"; else ui::info "reusing existing"; return 0; fi
    else
      ui::warn "non-interactive: reusing running server despite config mismatch"; return 0
    fi
  fi
  server::start "$profile" "$model" "$alias" "$port"
}

server::kill() {  # <port>
  local pid; pid="$(server::meta_get "$1" pid 2>/dev/null || true)"
  if [[ -z "$pid" ]]; then
    pid="$(pgrep -f "llama-server.*--port $1" 2>/dev/null | head -1)"
  fi
  [[ -n "$pid" ]] || { ui::info "no managed server on :$1"; return 0; }
  ui::info "killing pid $pid (:$1)"; kill "$pid" 2>/dev/null
  server::meta_clear "$1"
}
```

- [ ] **Step 4: Run to verify pass**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: all `server::*` assertions pass. (Start/kill/ensure are validated by manual smoke in Task 11.)

- [ ] **Step 5: `zsh -n` lint**

Run: `zsh -n conf/ai/llmm/lib/server.zsh`
Expected: no output, exit 0.

- [ ] **Step 6: Commit**

```bash
git add conf/ai/llmm/lib/server.zsh conf/ai/llmm/tests/test_server.zsh
git commit -m "feat(llmm): server lifecycle (resolve, args, start, ensure, kill, rotation)"
```

---

### Task 6: `lib/status.zsh` — system memory + log parse + report

**Files:**
- Create: `conf/ai/llmm/lib/status.zsh`
- Create: `conf/ai/llmm/tests/test_status.zsh`
- Create: `conf/ai/llmm/tests/fixtures/sample-server.log`

- [ ] **Step 1: Create the sample log fixture**

```bash
cat > conf/ai/llmm/tests/fixtures/sample-server.log <<'EOF'
llama_model_loader: loaded meta data
print_info: model size       =  18234.50 MiB
llama_kv_cache_unified: KV self size  =  4096.00 MiB
ggml_metal_init: Metal KV buffer size =  4096.00 MiB
ggml_metal: Metal compute buffer size =  1024.00 MiB
main: server is listening on http://127.0.0.1:11111
EOF
```

- [ ] **Step 2: Write failing tests for `status::parse_log`**

Create `conf/ai/llmm/tests/test_status.zsh`:

```zsh
source "$LLMM_LIB/ui.zsh"
source "$LLMM_LIB/config.zsh"
source "$LLMM_LIB/status.zsh"

log="$LLMM_TESTS_DIR/fixtures/sample-server.log"
assert_eq "$(status::parse_log "$log" model)" "18234.50 MiB" "parse model size"
assert_eq "$(status::parse_log "$log" kv)"    "4096.00 MiB"  "parse kv size"
assert_contains "$(status::parse_log "$log" metal)" "MiB" "parse metal size"
```

- [ ] **Step 3: Run to verify fail**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: FAIL on undefined `status::parse_log`.

- [ ] **Step 4: Implement `lib/status.zsh`**

```zsh
#!/usr/bin/env zsh
# status.zsh — hardware-oriented report for the managed server.

# status::parse_log <logfile> <model|kv|metal> -> echoes the matched size string.
status::parse_log() {
  local lf="$1" what="$2" line
  [[ -f "$lf" ]] || return 1
  case "$what" in
    model) line="$(grep -iE 'model size' "$lf" | head -1)" ;;
    kv)    line="$(grep -iE 'KV self size' "$lf" | head -1)" ;;
    metal) line="$(grep -iE 'Metal.*buffer size' "$lf" | head -1)" ;;
  esac
  [[ -n "$line" ]] || return 1
  # Extract the "<number> MiB" (or GiB) tail.
  print -r -- "${line##*= }" | sed -E 's/^[[:space:]]*//'
}

# status::mem_system -> one-line "RAM used / total (pct%)".
status::mem_system() {
  if [[ "$(uname)" == Darwin ]]; then
    local total_b pages_free pagesize free_b
    total_b=$(sysctl -n hw.memsize)
    pagesize=$(sysctl -n hw.pagesize)
    pages_free=$(vm_stat | awk '/Pages free/ {gsub(/\./,"",$3); print $3}')
    free_b=$(( pages_free * pagesize ))
    local total_g=$(( total_b / 1073741824 ))
    local used_g=$(( (total_b - free_b) / 1073741824 ))
    local pct=$(( (total_b - free_b) * 100 / total_b ))
    print -r -- "RAM ${used_g} / ${total_g} GiB used (${pct}%)"
  else
    awk '/MemTotal/{t=$2} /MemAvailable/{a=$2}
         END{u=(t-a); printf "RAM %.0f / %.0f GiB used (%d%%)\n", u/1048576, t/1048576, u*100/t}' /proc/meminfo
  fi
}

# status::report -> full report for the managed server on LLMM_PORT.
status::report() {
  local port="${LLMM_PORT:-11111}"
  print -r -- "$(status::mem_system)"
  if ! server::is_healthy "$port"; then
    print -r -- "no managed server running on :$port"
    return 0
  fi
  local pid alias model prof lf rss
  pid="$(server::meta_get "$port" pid)"
  alias="$(server::meta_get "$port" alias)"
  model="$(server::meta_get "$port" model)"
  prof="$(server::meta_get "$port" profile)"
  lf="$(server::meta_get "$port" logfile)"
  rss=$(ps -o rss= -p "$pid" 2>/dev/null | awk '{printf "%d MiB", $1/1024}')
  print -r -- "server  :$port  pid=$pid  alias=$alias  profile=$prof"
  print -r -- "  model : $model"
  print -r -- "  rss   : ${rss:-?}"
  print -r -- "  ctx   : $(server::meta_get "$port" ctx_size)"
  print -r -- "  model size : $(status::parse_log "$lf" model 2>/dev/null || echo '?')"
  print -r -- "  kv size    : $(status::parse_log "$lf" kv 2>/dev/null || echo '?')"
  print -r -- "  metal buf  : $(status::parse_log "$lf" metal 2>/dev/null || echo '?')"
}
```

- [ ] **Step 5: Run to verify pass + lint**

Run: `zsh conf/ai/llmm/tests/harness.zsh` (parse_log assertions pass)
Run: `zsh -n conf/ai/llmm/lib/status.zsh`
Expected: assertions pass; lint clean.

- [ ] **Step 6: Commit**

```bash
git add conf/ai/llmm/lib/status.zsh conf/ai/llmm/tests/test_status.zsh conf/ai/llmm/tests/fixtures/sample-server.log
git commit -m "feat(llmm): status report (system mem, log-parsed sizes, RSS)"
```

---

### Task 7: `lib/claude.zsh` — exec claude with ANTHROPIC_* env

**Files:**
- Create: `conf/ai/llmm/lib/claude.zsh`

- [ ] **Step 1: Implement (lint-only; this just execs claude)**

```zsh
#!/usr/bin/env zsh
# claude.zsh — launch Claude Code pointed at the local server.

# claude::launch <alias> <port> [claude args...]
claude::launch() {
  local alias="$1" port="$2"; shift 2
  exec env \
    ANTHROPIC_BASE_URL="http://127.0.0.1:$port" \
    ANTHROPIC_API_KEY="llama-cpp" \
    ANTHROPIC_AUTH_TOKEN="llama-cpp" \
    ANTHROPIC_DEFAULT_SONNET_MODEL="$alias" \
    ANTHROPIC_DEFAULT_HAIKU_MODEL="$alias" \
    ANTHROPIC_DEFAULT_OPUS_MODEL="$alias" \
    CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1 \
    claude "$@"
}
```

- [ ] **Step 2: Lint**

Run: `zsh -n conf/ai/llmm/lib/claude.zsh`
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add conf/ai/llmm/lib/claude.zsh
git commit -m "feat(llmm): claude launcher env wrapper"
```

---

## Stage 3 — Dispatcher

### Task 8: `llmm` dispatcher (routing + flag parsing)

**Files:**
- Create: `conf/ai/llmm/llmm`
- Test: extend `conf/ai/llmm/tests/test_config.zsh` with a routing test that stubs side-effecting functions.

- [ ] **Step 1: Write a failing routing test**

Append to `conf/ai/llmm/tests/test_config.zsh`:

```zsh
# Dispatcher routing: stub the heavy functions, assert the right one is called.
# Wrapped in a function (not a subshell) so assert_* update the harness counters,
# and so the dispatcher's options stay localized via local_options. The `help`
# assertion captures stderr (2>&1) because llmm::usage prints to stderr.
_test_llmm_dispatch() {
  emulate -L zsh
  setopt local_options
  export LLMM_ROOT="$LLMM_ROOT"
  # Source dispatcher in "library mode" so it defines llmm::* without running main.
  LLMM_NO_MAIN=1 source "$LLMM_ROOT/llmm"

  # Stub side-effecting deps.
  server::ensure() { print "ensure:$1:$2:$3:$4"; }
  claude::launch() { print "launch:$1:$2"; }
  models::pick()   { print "/picked/model-Q3_K_M.gguf"; }
  config::load()   { :; }
  LLMM_PORT=11111 LLMM_MODEL=/m.gguf LLMM_ALIAS=al

  assert_contains "$(llmm::route help 2>&1)" "usage" "route help"
  assert_rc 2 "$(llmm::route bogus >/dev/null 2>&1; echo $?)" "unknown subcommand rc"
}
_test_llmm_dispatch
```

- [ ] **Step 2: Run to verify fail**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: FAIL — `llmm::route` undefined.

- [ ] **Step 3: Implement `conf/ai/llmm/llmm`**

```zsh
#!/usr/bin/env zsh
# llmm — local-LLM server manager + Claude Code launcher.
emulate -L zsh
# Strict options live in llmm::main (the actual run), not at top level, so sourcing
# this file in library mode (LLMM_NO_MAIN=1, e.g. tests) keeps clean defaults.
# We deliberately do NOT use err_return: lib functions use non-zero return as data
# (server::meta_get -> "absent", server::is_healthy -> "not healthy"), and
# err_return would abort callers like status::report on those expected non-zeros.
# Error handling is explicit instead (|| exit 1, || ui::die).

# Resolve our real path (follows the PATH symlink back to the repo) and load libs.
: ${LLMM_ROOT:="${0:A:h}"}
for _u in ui config models server status claude; do
  source "$LLMM_ROOT/lib/$_u.zsh"
done

llmm::usage() {
  cat >&2 <<'EOF'
usage: llmm [command] [flags]

  (no command)        start default model, launch Claude Code
  pick                pick a model, then start + launch
  [pick] --minimal    use the minimal profile (small ctx, no warmup)
  pull <repo[:quant]> download a model into the dedicated store
  status | stat | stats   show server + hardware stats
  logs [-f] [--tail N]    tail the server log (default --tail 100)
  config              open the config in $EDITOR
  kill                stop the running server
  help                show this help
EOF
}

llmm::start_path() {  # <profile> [extra claude args...]
  local profile="$1"; shift
  local model="$LLMM_MODEL" alias="$LLMM_ALIAS"
  if [[ -n "${LLMM_PICK:-}" ]]; then
    model="$(models::pick)" || exit 1
    alias="${model:t:r}"
  fi
  if [[ -n "${SERVE_ONLY:-}" ]]; then
    server::ensure "$profile" "$model" "$alias" "$LLMM_PORT" || exit 1
    ui::info "SERVE_ONLY set — not launching claude"; exec tail -f /dev/null
  fi
  server::ensure "$profile" "$model" "$alias" "$LLMM_PORT" || exit 1
  claude::launch "$alias" "$LLMM_PORT" "$@"
}

llmm::cmd_logs() {
  local follow=0 tail_n=100
  while (( $# )); do
    case "$1" in
      -f|--follow) follow=1; shift ;;
      --tail) tail_n="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  local lf="$(server::logfile "$LLMM_PORT")"
  [[ -f "$lf" ]] || ui::die "no log at $lf"
  if (( follow )); then tail -n "$tail_n" -f "$lf"; else tail -n "$tail_n" "$lf"; fi
}

llmm::cmd_config() {
  config::seed
  local ed="${EDITOR:-${VISUAL:-nvim}}"
  exec "$ed" "$(config::file)"
}

# llmm::route <command> [args...] — pure routing; returns rc 2 on unknown command.
llmm::route() {
  local cmd="${1:-}"; [[ $# -gt 0 ]] && shift
  # --minimal may appear as the command's flag on start paths.
  local profile=default
  local -a rest=()
  local a
  for a in "$@"; do
    [[ "$a" == --minimal ]] && profile=minimal || rest+=("$a")
  done

  case "$cmd" in
    ''|start)      llmm::start_path "$profile" "${rest[@]}" ;;
    pick)          LLMM_PICK=1 llmm::start_path "$profile" "${rest[@]}" ;;
    pull)          models::pull "${rest[1]:-}" ;;
    status|stat|stats) status::report ;;
    logs)          llmm::cmd_logs "${rest[@]}" ;;
    config)        llmm::cmd_config ;;
    kill)          server::kill "$LLMM_PORT" ;;
    help|-h|--help) llmm::usage ;;
    *)             ui::err "unknown command: $cmd"; llmm::usage; return 2 ;;
  esac
}

llmm::main() {
  emulate -L zsh
  setopt no_unset pipe_fail
  config::load
  : ${LLMM_PORT:=11111}
  llmm::route "$@"
}

[[ -n "${LLMM_NO_MAIN:-}" ]] || llmm::main "$@"
```

- [ ] **Step 4: Run to verify pass + lint**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Run: `zsh -n conf/ai/llmm/llmm`
Expected: routing assertions pass; lint clean.

- [ ] **Step 5: Make executable + commit**

```bash
chmod +x conf/ai/llmm/llmm
git add conf/ai/llmm/llmm conf/ai/llmm/tests/test_config.zsh
git commit -m "feat(llmm): dispatcher with subcommand routing + profile flag"
```

---

## Stage 4 — Installer (bash, 3.2-safe)

### Task 9: `install.sh` — detect, deps, backend, build, symlink, seed

**Files:**
- Create: `conf/ai/llmm/install.sh`

**3.2-safety note:** no associative arrays, no `${var,,}`/`${var^^}` (use `tr`), no `mapfile`. Each such avoidance is commented inline. Flag any 3.2-unsafe construct found during review.

- [ ] **Step 1: Implement `install.sh`**

```bash
#!/usr/bin/env bash
# install.sh — build llama.cpp from source + install llmm deps, then wire up
# the llmm command. Bash 3.2-safe (macOS system bash). Idempotent.
#
# Usage: install.sh [--force] [--rebuild] [--backend cuda|vulkan|cpu]
set -euo pipefail

LLMM_SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/llmm"
CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/llmm"
BIN_DST="$HOME/.local/bin/llmm"

FORCE=false; REBUILD=false; BACKEND="${LLMM_BACKEND:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --force) FORCE=true; shift ;;
    --rebuild) REBUILD=true; shift ;;
    --backend) BACKEND="$2"; shift 2 ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
done

say()  { printf '==> %s\n' "$*"; }
warn() { printf 'warn: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }
has()  { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"; ARCH="$(uname -m)"
say "platform: $OS/$ARCH"

# --- base deps ---------------------------------------------------------------
ensure_base_deps() {
  has git   || die "git is required"
  has curl  || die "curl is required"
  if ! has cmake; then
    if [ "$OS" = Darwin ]; then die "cmake required: brew install cmake"; fi
    die "cmake required (e.g. apt install cmake / dnf install cmake)"
  fi
  if [ "$OS" = Darwin ] && ! has cc; then
    die "C toolchain required: xcode-select --install"
  fi
}

# --- backend selection -------------------------------------------------------
detect_backend() {
  if [ "$OS" = Darwin ]; then echo metal; return; fi
  if has nvidia-smi; then echo cuda; else echo cpu; fi
}

choose_backend() {
  if [ "$OS" = Darwin ]; then BACKEND=metal; return; fi
  local default; default="$(detect_backend)"
  if [ -n "$BACKEND" ]; then return; fi
  # Non-interactive (no TTY): take the detected default silently.
  if [ ! -t 0 ]; then BACKEND="$default"; say "backend: $BACKEND (auto, non-interactive)"; return; fi
  printf 'compute backend [cuda|vulkan|cpu] (default %s): ' "$default"
  read -r BACKEND || true
  [ -n "$BACKEND" ] || BACKEND="$default"
  # lowercase without ${var,,} (bash 3.2-safe): use tr.
  BACKEND="$(printf '%s' "$BACKEND" | tr '[:upper:]' '[:lower:]')"
}

cmake_backend_flags() {
  case "$1" in
    metal)  echo "-DGGML_METAL=ON" ;;
    cuda)   has nvcc || warn "nvcc not found; CUDA build may fail"; echo "-DGGML_CUDA=ON" ;;
    vulkan) echo "-DGGML_VULKAN=ON" ;;
    cpu)    echo "" ;;
    *)      die "unknown backend: $1" ;;
  esac
}

# --- build llama.cpp ---------------------------------------------------------
build_llamacpp() {
  local src="$DATA_DIR/src/llama.cpp"
  mkdir -p "$DATA_DIR/src" "$DATA_DIR/bin"
  if [ ! -d "$src/.git" ]; then
    say "cloning llama.cpp"
    git clone --depth 1 https://github.com/ggml-org/llama.cpp "$src"
  else
    say "updating llama.cpp"
    git -C "$src" pull --ff-only || warn "git pull failed; building current checkout"
  fi
  if $REBUILD; then rm -rf "$src/build"; fi
  local flags; flags="$(cmake_backend_flags "$BACKEND")"
  say "configuring (backend=$BACKEND)"
  # shellcheck disable=SC2086
  cmake -S "$src" -B "$src/build" -DCMAKE_BUILD_TYPE=Release -DLLAMA_CURL=ON $flags
  say "building (this can take several minutes)"
  cmake --build "$src/build" --config Release -j --target llama-server
  # Install the server + shared libs into the XDG bin dir.
  find "$src/build/bin" -maxdepth 1 -type f -name 'llama-server' -exec cp {} "$DATA_DIR/bin/" \;
  find "$src/build/bin" -maxdepth 1 \( -name '*.dylib' -o -name '*.so' -o -name '*.so.*' \) \
    -exec cp {} "$DATA_DIR/bin/" \; 2>/dev/null || true
  [ -x "$DATA_DIR/bin/llama-server" ] || die "build did not produce llama-server"
  say "installed llama-server -> $DATA_DIR/bin"
}

# --- python tooling (uv + huggingface CLI) -----------------------------------
ensure_uv_hf() {
  if ! has uv; then
    say "installing uv"
    curl -LsSf https://astral.sh/uv/install.sh | sh || { warn "uv install failed; pulls will fall back to --hf-repo"; return 0; }
    # uv installs to ~/.local/bin which we expect on PATH.
  fi
  if has uv && ! has hf; then
    say "installing huggingface_hub CLI"
    uv tool install "huggingface_hub[cli]" || warn "hf install failed; pulls will fall back to --hf-repo"
  fi
}

# --- zsh + fzf checks --------------------------------------------------------
ensure_runtime_tools() {
  has zsh || warn "zsh not found — llmm requires zsh at runtime (install it for your platform)"
  has fzf || warn "fzf not found — 'llmm pick' will use a numbered menu"
}

# --- symlink + seed ----------------------------------------------------------
link_and_seed() {
  mkdir -p "$HOME/.local/bin" "$CFG_DIR" "$DATA_DIR/models"
  if [ -e "$BIN_DST" ] && [ ! -L "$BIN_DST" ]; then
    if $FORCE; then mv "$BIN_DST" "$BIN_DST.pre-evangelist.bak"
    else die "refusing to overwrite regular file $BIN_DST (re-run with --force)"; fi
  fi
  ln -sfn "$LLMM_SRC_DIR/llmm" "$BIN_DST"
  say "linked $BIN_DST -> $LLMM_SRC_DIR/llmm"
  if [ ! -f "$CFG_DIR/config.zsh" ]; then
    cp "$LLMM_SRC_DIR/config.default.zsh" "$CFG_DIR/config.zsh"
    say "seeded $CFG_DIR/config.zsh"
  fi
}

main() {
  ensure_base_deps
  choose_backend
  if $REBUILD || [ ! -x "$DATA_DIR/bin/llama-server" ]; then build_llamacpp; else say "llama-server already built (use --rebuild to force)"; fi
  ensure_uv_hf
  ensure_runtime_tools
  link_and_seed
  say "done. Run 'llmm' to start, or 'llmm help'."
  case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) warn "add ~/.local/bin to PATH";; esac
}
main
```

- [ ] **Step 2: Lint**

Run: `bash -n conf/ai/llmm/install.sh`
Run (if available): `shellcheck conf/ai/llmm/install.sh` and review warnings.
Expected: `bash -n` clean.

- [ ] **Step 3: Verify 3.2 safety manually**

Inspect for: associative arrays (`declare -A`), `${var,,}`, `${var^^}`, `mapfile`/`readarray`, `&>>`. Expected: none present (lowercasing uses `tr`). Confirm in review.

- [ ] **Step 4: Make executable + commit**

```bash
chmod +x conf/ai/llmm/install.sh
git add conf/ai/llmm/install.sh
git commit -m "feat(llmm): bash installer (build llama.cpp, deps, symlink, seed)"
```

---

## Stage 5 — evangelist wiring

### Task 10: Wire `llmm` into `evn install` / `evn update`

**Files:**
- Modify: `_impl/install.bash4` (add `install::llmm_settings`)
- Modify: `_impl/control.sh` (add `llmm)` case ~line 226; add update trigger ~line 402-408; help; modulecheck ~line 108-116)
- Modify: `.update-list` (add `llmm:0`)

- [ ] **Step 1: Add the shim in `_impl/install.bash4`**

Append after `install::ai_settings` (after line 587):

```bash
install::llmm_settings() {
  ECHO Installing llmm local-LLM manager..

  ## macOS + Linux; builds llama.cpp from source via the canonical installer.
  local -a args=()
  [[ "${_AI_FORCE:-false}" == true ]] && args+=(--force)
  bash "$EVANGELIST/conf/ai/llmm/install.sh" "${args[@]}" || return 1

  ECHO Successfully installed: llmm.
}
```

- [ ] **Step 2: Add the install case in `_impl/control.sh`**

At the component `case` (line ~226, next to `ai) install::ai_settings ;;`):

```bash
    llmm) install::llmm_settings ;;
```

- [ ] **Step 3: Add the update trigger in `_impl/control.sh`**

After the existing `ai` update block (line ~402-408), add:

```bash
  if grep -qE '^conf/ai/llmm/' <<<"$UPD" && grep -q '^llmm' .update-list; then
    ECHO Refreshing llmm..
    bash "$EVANGELIST/conf/ai/llmm/install.sh" || ECHO2 "llmm refresh failed"
  fi
```

- [ ] **Step 4: Register the component for arg validation + help + modulecheck**

Locate `install::check_arguments` and the component list used by it / `control::help` (grep for `ai)` and the help text). Add `llmm` everywhere `ai` appears as a valid component token. In `install::define_modules` (the `write::modulecheck` block ~line 108-116) add:

```bash
  write::modulecheck LLMM o:cmake o:llama-server o:fzf o:uv
```

Run to find every spot:
```bash
grep -n "ai)\|'ai'\|\"ai\"\| ai \|ai|" _impl/control.sh _impl/install.bash4 _impl/completions/* 2>/dev/null
```
Add `llmm` alongside `ai` in: the valid-component regex/list, the help listing, and shell completion candidate lists.

- [ ] **Step 5: Add to `.update-list`**

Append a line so `evn update` recognizes the component as installed:

```
llmm:0
```

(Set to `1` automatically by `utils::update_status` after a successful install; `0` is the not-yet-installed seed.)

- [ ] **Step 6: Verify evn parses the new component**

Run: `bash evangelist.sh install --help 2>&1 | grep -i llmm || true`
Run: `bash -n _impl/install.bash4 && bash -n _impl/control.sh`
Expected: no syntax errors; `llmm` appears in help/usage.

- [ ] **Step 7: Commit**

```bash
git add _impl/install.bash4 _impl/control.sh .update-list _impl/completions
git commit -m "feat(evn): add llmm component (install + update wiring)"
```

---

## Stage 6 — Migration, manual smoke, docs

### Task 11: Manual smoke test against a real server

**Files:** none (verification only)

- [ ] **Step 1: Build + install via evn**

Run: `bash evangelist.sh install llmm`
Expected: llama.cpp builds, `~/.local/bin/llmm` symlink created, config seeded. (On macOS, Metal backend; first build takes minutes.)

- [ ] **Step 2: Smoke each subcommand**

```
llmm help            # usage prints
llmm status          # system RAM line + "no managed server running"
llmm --minimal       # starts minimal-profile server, launches claude; /exit
llmm status          # now shows pid/alias/model/rss/ctx/kv/metal
llmm logs --tail 20  # last 20 log lines
llmm kill            # stops the server
llmm pick            # picker lists discovered models (fzf or numbered)
```

Expected: each behaves as described; `status` numbers are sane; `kill` removes the `.meta`.

- [ ] **Step 3: Record results in the task notes (no commit unless fixes needed).**

---

### Task 12: Remove `lcpp.claude`, run the full test suite, update docs

**Files:**
- Delete: `conf/ai/lcpp.claude`
- Modify: `conf/ai/README.md` (document `llmm`)
- Modify: `docs/roadmap` (`Later`: v1.1 multi-server, Phase-2 context reduction) if a roadmap exists; else skip per repo convention.

- [ ] **Step 1: Run the full zsh test suite green**

Run: `zsh conf/ai/llmm/tests/harness.zsh`
Expected: `0 failure(s)`, exit 0.

- [ ] **Step 2: Remove the superseded launcher**

```bash
git rm conf/ai/lcpp.claude
```

(The manual `~/.local/bin/lcpp.claude` symlink is replaced by `llmm` from Task 10; remove it locally: `rm -f ~/.local/bin/lcpp.claude`.)

- [ ] **Step 3: Document `llmm` in `conf/ai/README.md`**

Add a section describing the command surface, config location (`~/.config/llmm/config.zsh`), model store (`~/.local/share/llmm/models`), and `evn install llmm`. Keep README.md as Markdown (landing-page convention).

- [ ] **Step 4: Log deferred work to roadmap `Later` (only if `docs/roadmap` exists)**

```bash
ls docs/roadmap >/dev/null 2>&1 && echo "roadmap present — append v1.1 multi-server + Phase-2 context reduction to Later" || echo "no roadmap — skip"
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(llmm): retire lcpp.claude; document llmm; log deferred work"
```

---

## Self-Review (completed during authoring)

- **Spec coverage:** command surface (Task 8), config+profiles (Task 3), code layout (Tasks 2-8), build/deps installer (Task 9), runtime state + rotation (Task 5), status internals (Task 6), evn integration (Task 10), migration (Task 12), models dir/HF convergence (Tasks 4-5). `llmm pull` (Task 4) covered. Single-server reuse/restart semantics (Task 5 `server::ensure`). All spec sections map to a task.
- **Placeholders:** none — every code step shows complete code; `config::reset_dirs` is intentionally a no-op (dirs computed live) and documented as such.
- **Type/name consistency:** `server::ensure/start/kill/meta_get/meta_write/build_args/should_rotate/resolve_bin/lib_dir`, `config::pf/load/seed/file/models_dir/state_dir/bin_dir`, `models::label/discover/pick/pull`, `status::parse_log/mem_system/report`, `claude::launch`, `ui::menu/pick_index/has/die` — used consistently across tasks and the dispatcher.

## Deferred (from spec)

- **v1.1:** multiple concurrent port-keyed servers with picker in logs/status/kill (`.meta`/log keying already in place).
- **Phase 2:** Claude Code context-footprint reduction for small local windows.
- **Backend abstraction:** `backend=ollama|llamacpp` to fold in `lclaude`.
