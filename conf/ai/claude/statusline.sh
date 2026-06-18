#!/bin/sh
## Router: pick bash 4+ (statusline_bash.sh) or fall back to zsh (statusline.zsh).
## Resolves this file's own symlink so sibling impl scripts are always found
## in the same source directory regardless of where ~/.claude points.

target=$(readlink "$0" 2>/dev/null)
dir=$(cd "$(dirname "${target:-$0}")" && pwd)

if bash_bin=$(command -v bash 2>/dev/null); then
  ver=$("$bash_bin" -c 'echo ${BASH_VERSINFO[0]}' 2>/dev/null)
  if [ "${ver:-0}" -ge 4 ] 2>/dev/null; then
    exec "$bash_bin" "$dir/statusline.bash"
  fi
fi

if zsh_bin=$(command -v zsh 2>/dev/null); then
  exec "$zsh_bin" "$dir/statusline.zsh"
fi

printf 'statusline: no suitable shell found (need bash 4+ or zsh)\n' >&2
exit 1
