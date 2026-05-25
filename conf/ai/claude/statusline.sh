#!/usr/bin/env bash

## Claude Code statusline (two lines):
##   row 1: cwd · git branch · context bar
##   row 2: [5h% (↻…) · 7d% (↻…) ·] $cost
##
## `cost.total_cost_usd` is a client-side token-cost estimate, always
## present. For subscribers it is informational (what the session would
## cost on API billing) rather than an actual bill.
##
## `rate_limits` is sent only to Claude.ai Pro/Max subscribers, so the
## 5h-session and 7d-all-models usage % render only for them. (For the
## first subscriber message the inner fields may not be populated yet,
## so both percentages flash 0% once — harmless.)

input=$(cat)

mapfile -t fields < <(
  echo "$input" | jq -r '
    .workspace.current_dir // .cwd // "",
    (.context_window.used_percentage // 0 | floor),
    (.cost.total_cost_usd // 0),
    has("rate_limits"),
    (.rate_limits.five_hour.used_percentage // 0 | floor),
    (.rate_limits.seven_day.used_percentage // 0 | floor),
    (.rate_limits.five_hour.resets_at // 0),
    (.rate_limits.seven_day.resets_at // 0)
  '
)
cwd=${fields[0]}
pct=${fields[1]}
cost=${fields[2]}
subscriber=${fields[3]}
five_hr=${fields[4]}
seven_day=${fields[5]}
five_hr_reset=${fields[6]}
seven_day_reset=${fields[7]}

## Short local-time label for a Unix-epoch reset, e.g. "Sat 18:42".
## Day-of-week is unambiguous within the 7-day window.
fmt_reset() {
  [ "$1" -gt 0 ] 2>/dev/null && date -d "@$1" +'%a %H:%M' 2>/dev/null
}

[ -z "$cwd" ] && cwd=$(pwd)
[ "$pct" -gt 100 ] 2>/dev/null && pct=100

GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BLUE='\033[34m'
DIM='\033[2m'
RESET='\033[0m'

## Segment colours mirror the agkozak PS1 palette
PWD_COLOR='\033[1;38;5;226;44m'  # bold pure-yellow (256-color) on blue background
BRANCH_COLOR='\033[31m'    # red

## green <70%, yellow 70-89%, red 90%+
pct_color() {
  if [ "$1" -ge 90 ]; then printf '%s' "$RED"
  elif [ "$1" -ge 70 ]; then printf '%s' "$YELLOW"
  else printf '%s' "$GREEN"; fi
}

## ~-collapsed path, mirrors the bash \w prompt segment
disp_cwd="${cwd/#$HOME/\~}"

branch=$(git -C "$cwd" branch --show-current 2>/dev/null)

## git branch status symbols, mirroring the agkozak PS1 prompt:
##   > renamed   + new file   x deleted   ! modified   ? untracked
##   * ahead     & behind     % diverged
branch_symbols() {
  local porcelain bl rest line xy sym=""
  local renamed=0 newfile=0 deleted=0 modified=0 untracked=0 ahead=0 behind=0
  porcelain=$(git -C "$cwd" status --porcelain=v1 --branch 2>/dev/null) || return
  bl=${porcelain%%$'\n'*}
  rest=${porcelain#*$'\n'}
  [ "$rest" = "$porcelain" ] && rest=""

  [[ $bl == *'[ahead '* || $bl == *', ahead '* ]] && ahead=1
  [[ $bl == *'behind '* ]] && behind=1

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    xy=${line:0:2}
    case $xy in
      '??') untracked=1 ;;
      R*|*R) renamed=1 ;;
      A*) newfile=1 ;;
      D*|*D) deleted=1 ;;
      M*|*M) modified=1 ;;
    esac
  done <<< "$rest"

  [ "$renamed" = 1 ] && sym+='>'
  [ "$newfile" = 1 ] && sym+='+'
  [ "$deleted" = 1 ] && sym+='x'
  [ "$modified" = 1 ] && sym+='!'
  [ "$untracked" = 1 ] && sym+='?'
  if [ "$ahead" = 1 ] && [ "$behind" = 1 ]; then sym+='%'
  elif [ "$ahead" = 1 ]; then sym+='*'
  elif [ "$behind" = 1 ]; then sym+='&'; fi

  [ -n "$sym" ] && printf ' %s' "$sym"
}

[ -n "$branch" ] && branch="${branch}$(branch_symbols)"

bar_color=$(pct_color "$pct")
filled=$((pct / 10))
empty=$((10 - filled))
printf -v fill "%${filled}s"
printf -v pad "%${empty}s"
bar="${fill// /█}${pad// /░}"

pipe=" ${DIM}|${RESET} "
dot=" ${DIM}·${RESET} "
cost_seg="${YELLOW}💰 $(printf '%.2f' "$cost")${RESET}"

line="${PWD_COLOR} ${disp_cwd} ${RESET}"
if [ -n "$branch" ]; then
  line="${line}  ${BRANCH_COLOR}🌿 ${branch}${RESET}${pipe}${bar_color}${bar}${RESET} ${pct}% ctx"
else
  line="${line}  ${bar_color}${bar}${RESET} ${pct}% ctx"
fi
if [ "$subscriber" = "true" ]; then
  five_hr_color=$(pct_color "$five_hr")
  seven_day_color=$(pct_color "$seven_day")
  five_hr_at=$(fmt_reset "$five_hr_reset")
  seven_day_at=$(fmt_reset "$seven_day_reset")
  five_hr_suffix=${five_hr_at:+ ${DIM}(↻${five_hr_at})${RESET}}
  seven_day_suffix=${seven_day_at:+ ${DIM}(↻${seven_day_at})${RESET}}
  line="${line}\n${DIM}5h${RESET} ${five_hr_color}${five_hr}%${RESET}${five_hr_suffix}${dot}${DIM}7d${RESET} ${seven_day_color}${seven_day}%${RESET}${seven_day_suffix}${dot}${cost_seg}"
else
  line="${line}\n${cost_seg}"
fi
printf '%b\n' "$line"
