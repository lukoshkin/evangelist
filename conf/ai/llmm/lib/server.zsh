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
  a+=(--ctx-size "$(config::ctx_size "$profile")")
  a+=(--flash-attn "$(config::pf "$profile" flash_attn)")
  a+=(--jinja)
  a+=(--n-gpu-layers "$(config::pf "$profile" gpu_layers)")
  local _ckpts; _ckpts="$(config::pf "$profile" ctx_checkpoints)"
  [[ -n "$_ckpts" ]] && a+=(--ctx-checkpoints "$_ckpts")
  local _par; _par="$(config::pf "$profile" parallel)"
  [[ -n "$_par" ]] && a+=(--parallel "$_par")
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
      server::meta_write "$port" "$pid" "$model" "$alias" "$(config::ctx_size "$profile")" "$profile"
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
    local ralias="$(server::meta_get "$port" alias 2>/dev/null || true)"
    local rprof="$(server::meta_get "$port" profile 2>/dev/null || true)"
    if [[ -z "$ralias" ]]; then
      ui::warn "a foreign server is healthy on :$port (not started by llmm); reusing it"
      return 0
    fi
    # Identity is the canonical alias, so an HF repo spec and the downloaded
    # .gguf for the same model are treated as the same server (no restart prompt).
    if [[ "$ralias" == "$alias" && "$rprof" == "$profile" ]]; then
      ui::info "reusing running server :$port ($ralias)"
      return 0
    fi
    if [[ -t 0 ]]; then
      print -u2 -n "running server is $ralias ($rprof); switch to $alias ($profile)? [y/N] "
      local ans; read -r ans
      if [[ "$ans" == [yY]* ]]; then server::kill "$port"; else ui::info "keeping $ralias"; return 0; fi
    else
      ui::warn "non-interactive: keeping running $ralias despite requested $alias"; return 0
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
