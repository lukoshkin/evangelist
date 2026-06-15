#!/usr/bin/env zsh
# status.zsh — hardware-oriented report for the managed server.

# status::file_size <path> -> human size of a file, or rc 1 if not a file.
# Robust + version-independent (vs scraping llama.cpp's startup banner, whose
# wording changes between releases).
status::file_size() {
  local f="$1" bytes
  [[ -f "$f" ]] || return 1
  bytes=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f" 2>/dev/null) || return 1
  awk -v b="$bytes" 'BEGIN { if (b >= 1073741824) printf "%.1f GiB", b/1073741824; else printf "%.0f MiB", b/1048576 }'
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
  local pid alias model prof rss size
  pid="$(server::meta_get "$port" pid)"
  alias="$(server::meta_get "$port" alias)"
  model="$(server::meta_get "$port" model)"
  prof="$(server::meta_get "$port" profile)"
  rss=$(ps -o rss= -p "$pid" 2>/dev/null | awk '{printf "%d MiB", $1/1024}')
  size="$(status::file_size "$model" 2>/dev/null)"
  print -r -- "server  :$port  pid=$pid  alias=$alias  profile=$prof"
  print -r -- "  model : $model"
  [[ -n "$size" ]] && print -r -- "  size  : $size"
  print -r -- "  rss   : ${rss:-?}"
  print -r -- "  ctx   : $(server::meta_get "$port" ctx_size)"
}
