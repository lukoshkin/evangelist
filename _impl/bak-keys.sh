#!/usr/bin/env bash

declare -A DIRS=(
  [keys-0.dconf]=/org/gnome/desktop/wm/keybindings/
  [keys-1.dconf]=/org/gnome/mutter/keybindings/
  [keys-2.dconf]=/org/gnome/mutter/wayland/keybindings/
  [keys-3.dconf]=/org/gnome/settings-daemon/plugins/media-keys/
)

keys::save () {
  [[ -z $1 || $1 = '/' ]] && prefix= || prefix="$1/"

  for key in "${!DIRS[@]}"; do
    if [[ -n $(dconf list "${DIRS[$key]}") ]]; then
      dconf dump "${DIRS[$key]}" > "${prefix}${key}"
    fi
  done
}

keys::load () {
  local keys_dir=${1:-.}
  echo "Looking for keys in $keys_dir"

  if [[ $keys_dir =~ ^[/]+$ ]]; then
    echo "Are you sure about your privileges?"
  fi

  declare -a FOUND
  mapfile -t < <(ls "${keys_dir}/"keys-*.dconf 2> /dev/null) FOUND

  for key in "${FOUND[@]}"; do
    dconf load "${DIRS[${key##*/}]}" < "${key}"
  done
  echo Restored successfully!
}
