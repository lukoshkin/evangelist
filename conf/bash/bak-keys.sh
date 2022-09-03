#!/usr/bin/env bash

declare -A DIRS=(
  [keys-0.dconf]=/org/gnome/desktop/wm/keybindings/
  [keys-1.dconf]=/org/gnome/mutter/keybindings/
  [keys-2.dconf]=/org/gnome/mutter/wayland/keybindings/
  [keys-3.dconf]=/org/gnome/settings-daemon/plugins/media-keys/
)

backup () {
  [[ $# -eq 0 || $1 = '/' ]] && prefix= || prefix="$1/"

  for key in "${!DIRS[@]}"; do
    if [[ -n $(dconf list ${DIRS[$key]}) ]]; then
      dconf dump ${DIRS[$key]} > "${prefix}${key}"
    fi
  done
}

restore () {
  local keys_dir=$1
  echo "Looking for keys in $keys_dir"

  if [[ $keys_dir =~ ^[/]+$ ]]; then
    echo "Are you sure about your privileges?"
  fi

  declare -a FOUND=( "$(ls "${keys_dir}"keys-*.dconf 2> /dev/null)" )

  for key in "${FOUND[@]}"; do
    dconf load ${DIRS[${key##*/}]} < ${key}
  done
}



case $1 in
  backup) backup "$2" ;;
  restore) restore "$2" ;;
esac
