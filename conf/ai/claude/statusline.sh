#!/usr/bin/env bash

## Claude Code statusline (single line): cwd · git branch · context bar.
## Session cost is appended only on usage-based (API) billing.
##
## Billing detection: Claude Code sends the `rate_limits` field only to
## Claude.ai Pro/Max subscribers. Its absence => pay-per-token billing,
## so cost is worth showing. (For the first message of a subscriber
## session rate_limits is not yet populated, so cost may flash once at
## $0.00 — harmless.)

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -z "$cwd" ] && cwd=$(pwd)
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
subscriber=$(echo "$input" | jq -r 'has("rate_limits")')

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

## context bar colour: green <70%, yellow 70-89%, red 90%+
if [ "$pct" -ge 90 ]; then bar_color="$RED"
elif [ "$pct" -ge 70 ]; then bar_color="$YELLOW"
else bar_color="$GREEN"; fi

filled=$((pct / 10))
empty=$((10 - filled))
printf -v fill "%${filled}s"
printf -v pad "%${empty}s"
bar="${fill// /█}${pad// /░}"

line="${PWD_COLOR} ${disp_cwd} ${RESET}"
[ -n "$branch" ] && line="${line}  ${BRANCH_COLOR}🌿 ${branch}${RESET}"
line="${line}  ${bar_color}${bar}${RESET} ${pct}% ctx"
if [ "$subscriber" != "true" ]; then
  line="${line} ${DIM}|${RESET} ${YELLOW}💰 $(printf '%.2f' "$cost")${RESET}"
fi
printf '%b\n' "$line"
