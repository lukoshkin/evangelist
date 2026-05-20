#!/usr/bin/env bash
## conf/ai/install.sh — provision Claude Code config and convert it to
## the other assistants. Invoked by evangelist's `ai` component.
## Usage: install.sh [MODE] [TOOL]
##   MODE = 1 (scripted + finalize) | 2 (delegate)   — default 1
##   TOOL = codex | copilot | cursor | all           — default all

set -euo pipefail

AI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SRC="$AI_DIR/claude"
STAMP_DIR="$AI_DIR/convert/tested-versions"
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
  ## render <tool> <template> <out> <phase> — substitute placeholders
  local tool template out phase stamp_path current_version recorded_version
  tool="$1"
  template="$2"
  out="$3"
  phase="$4"
  stamp_path="$STAMP_DIR/$tool.txt"
  current_version="$(detect_tool_version "$tool")"
  recorded_version="$(recorded_tested_version "$tool")"

  (
    cd "$AI_DIR"
    python3 -m convert.prompt_render \
      --template "$template" \
      --output "$out" \
      --tool "$tool" \
      --phase "$phase" \
      --ai-dir "$AI_DIR" \
      --claude-src "$CLAUDE_SRC" \
      --stamp-path "$stamp_path" \
      --current-tool-version "$current_version" \
      --recorded-tested-version "$recorded_version"
  )
}

detect_tool_version() {
  local tool version
  tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'unknown (%s binary not found locally)' "$tool"
    return
  fi

  version="$("$tool" --version 2>/dev/null | head -n 1 || true)"
  [[ -n "$version" ]] || version="$("$tool" -v 2>/dev/null | head -n 1 || true)"
  [[ -n "$version" ]] || version="unknown ($tool did not report a version)"
  version="${version%.}"
  printf '%s' "$version"
}

recorded_tested_version() {
  local tool stamp_path version
  tool="$1"
  stamp_path="$STAMP_DIR/$tool.txt"
  if [[ ! -f "$stamp_path" ]]; then
    printf 'unrecorded'
    return
  fi

  version="$(sed -n 's/^tested-version: //p' "$stamp_path" | head -n 1)"
  [[ -n "$version" ]] || version="unrecorded"
  printf '%s' "$version"
}

if [[ "$MODE" == "1" ]]; then
  if [[ "$TOOL" == all ]]; then
    ( cd "$AI_DIR" && python3 -m convert.convert )
  else
    ( cd "$AI_DIR" && python3 -m convert.convert --tool "$TOOL" )
  fi
  for tool in "${_tools[@]}"; do
    render "$tool" "$AI_DIR/convert/prompts/finalize.md.tmpl" \
      "$PROMPT_DIR/$tool-FINALIZE.md" "finalize"
  done
  echo "Mode 1: converted ($TOOL). Review prompts in $PROMPT_DIR/"
else
  for tool in "${_tools[@]}"; do
    render "$tool" "$AI_DIR/convert/prompts/delegate.md.tmpl" \
      "$PROMPT_DIR/$tool-DELEGATE.md" "delegate"
  done
  echo "Mode 2: open the target assistant(s) and run the prompt(s) in $PROMPT_DIR/"
fi
