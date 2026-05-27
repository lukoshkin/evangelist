#!/bin/zsh
set -e

if [[ "$(uname)" != Darwin ]]; then
  print -u2 'evangelist.macos.zsh is intended for macOS only.'
  exit 1
fi

script_dir=${0:A:h}
bash_candidates=(
  /opt/homebrew/bin/bash
  /usr/local/bin/bash
)
[[ -n "${HOMEBREW_PREFIX:-}" ]] && bash_candidates=("$HOMEBREW_PREFIX/bin/bash" $bash_candidates)

for bash_path in $bash_candidates; do
  if [[ -x "$bash_path" ]] && "$bash_path" -c '[[ ${BASH_VERSINFO[0]} -ge 4 ]]' 2>/dev/null; then
    exec "$bash_path" "$script_dir/evangelist.sh" "$@"
  fi
done

print -u2 'Homebrew Bash 4+ is required to run evangelist on macOS.'
print -u2 'Run ./sudo.builder.macos.zsh first, or install Bash with: brew install bash'
exit 1
