#!/bin/bash
## Not executable, the shebang is for syntax.

o() {
  command open "$@"
}

st() { # git STatus or STorage
  if [[ -n $1 ]] || ! git status 2>/dev/null; then
    if [[ $PWD = "$HOME" ]]; then
      echo "You are in the home directory."
      return 1
    fi

    command du -hm -d 1 "${@:-.}" | sort -h -r
  fi
}

_run_with_timeout() {
  local seconds=$1
  shift

  python3 - "$seconds" "$@" <<'PY'
import subprocess
import sys

timeout = float(sys.argv[1])
command = sys.argv[2:]

try:
    completed = subprocess.run(command, timeout=timeout)
except subprocess.TimeoutExpired:
    sys.exit(124)

sys.exit(completed.returncode)
PY
}

dtree() {
  local w8
  [[ -n $1 ]] && w8=$1 || w8=.5

  _run_with_timeout "$w8" find . ! -path '*/\.*' -type d &>/dev/null

  if [[ $? -eq 124 ]]; then
    echo 'Try to run it in one of subfolders.'
    return
  fi

  find . -not -path '*/.*' -type d -print | sed -e \
    's;[^-][^\/]*\/;--;g' -e 's;^;   ;' -e 's;-;|;'
}

tree() {
  if ! _has_external_command tree; then
    dtree "$1"
    return
  fi

  local w8
  local hierarchy

  [[ -n $1 ]] && w8=$1 || w8=.1
  hierarchy=$(_run_with_timeout "$w8" script -q /dev/null tree)

  if [[ $? -eq 124 ]]; then
    echo 'Try to run it in one of subfolders.'
    return
  fi

  hierarchy=${hierarchy#$'^D\b\b'}
  hierarchy=${hierarchy//$'\r'/}
  printf '%s\n' "$hierarchy"
}
