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
