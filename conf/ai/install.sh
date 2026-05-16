#!/usr/bin/env bash
## conf/ai/install.sh — provision Claude Code config and convert it to
## the other assistants. Invoked by evangelist's `ai` component.
## Usage: install.sh [MODE] [TOOL]
##   MODE = 1 (scripted + finalize) | 2 (delegate)   — default 1
##   TOOL = codex | copilot | cursor | all           — default all

set -euo pipefail

AI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SRC="$AI_DIR/claude"
MODE="${1:-1}"
TOOL="${2:-all}"

## --- symlink the canonical Claude artifacts into ~/.claude ---
mkdir -p "$HOME/.claude"
for item in commands skills scripts CLAUDE.md statusline.sh settings.json; do
  src="$CLAUDE_SRC/$item"
  dst="$HOME/.claude/$item"
  [[ -e "$src" ]] || continue
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    mv "$dst" "$dst.pre-evangelist.bak"
  fi
  ln -sfn "$src" "$dst"
done
echo "Linked Claude Code artifacts into ~/.claude"

## --- other-tool conversion ---
PROMPT_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/evangelist/ai-migration"
mkdir -p "$PROMPT_DIR"

if [[ "$TOOL" == all ]]; then
  _tools=(codex copilot cursor)
else
  _tools=("$TOOL")
fi

render() {
  ## render <tool> <template> <out> — substitute the @VAR@ placeholders
  sed -e "s|@TOOL@|$1|g" -e "s|@CLAUDE_SRC@|$CLAUDE_SRC|g" \
      -e "s|@AI_DIR@|$AI_DIR|g" "$2" >"$3"
}

if [[ "$MODE" == "1" ]]; then
  if [[ "$TOOL" == all ]]; then
    ( cd "$AI_DIR" && python3 -m convert.convert )
  else
    ( cd "$AI_DIR" && python3 -m convert.convert --tool "$TOOL" )
  fi
  for tool in "${_tools[@]}"; do
    render "$tool" "$AI_DIR/convert/prompts/finalize.md.tmpl" \
      "$PROMPT_DIR/$tool-FINALIZE.md"
  done
  echo "Mode 1: converted ($TOOL). Review prompts in $PROMPT_DIR/"
else
  for tool in "${_tools[@]}"; do
    render "$tool" "$AI_DIR/convert/prompts/delegate.md.tmpl" \
      "$PROMPT_DIR/$tool-DELEGATE.md"
  done
  echo "Mode 2: open the target assistant(s) and run the prompt(s) in $PROMPT_DIR/"
fi
