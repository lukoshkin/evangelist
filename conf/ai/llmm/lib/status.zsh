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
  # Healthy but no .meta -> a server llmm did not start (e.g. a stray
  # llama-server on the same port). Report it plainly instead of blanks.
  if [[ ! -f "$(server::metafile "$port")" ]]; then
    local fpid="$(pgrep -f "llama-server.*--port $port" 2>/dev/null | head -1)"
    print -r -- "server  :$port  foreign (healthy, not started by llmm${fpid:+; pid=$fpid})"
    print -r -- "  stop it with 'llmm kill', then 'llmm' to start a managed one"
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
