#!/usr/bin/env zsh
# models.zsh — discover local + HF-cache GGUFs, format labels, pick, pull.

# models::label <path> -> human label. HF-cache paths render as "[hf] org/repo  file".
models::label() {
  local f="$1"
  if [[ "$f" == */huggingface/hub/models--* || "$f" == */llmm/models/*models--* ]]; then
    local dir org rest
    dir="${f##*/models--}"; dir="${dir%%/*}"   # e.g. org--repo--with--dashes
    org="${dir%%--*}"                            # first segment
    rest="${dir#*--}"                            # remainder, dashes intact
    printf '[hf]    %-50s  %s' "$org/$rest" "${f:t}"
  else
    printf '[local] %s' "${f:t}"
  fi
}

# models::discover -> one absolute path per line, sorted+unique.
# Search dirs: models dir, legacy state models dir, default HF hub. Overridable
# for tests via LLMM_DISCOVER_DIRS array.
models::discover() {
  local -a dirs
  if (( ${+LLMM_DISCOVER_DIRS} )); then
    dirs=("${LLMM_DISCOVER_DIRS[@]}")
  else
    dirs=(
      "$(config::models_dir)"
      "${XDG_STATE_HOME:-$HOME/.local/state}/models"
      "${XDG_CACHE_HOME:-$HOME/.cache}/huggingface/hub"
    )
  fi
  local d
  for d in "${dirs[@]}"; do
    [[ -d "$d" ]] || continue
    # -L dereferences the snapshots/*.gguf symlinks the HF hub uses.
    find -L "$d" -maxdepth 6 -name '*.gguf' -type f 2>/dev/null
  done | sort -u
}

# models::pick -> echoes a chosen model path, rc 1 on abort/none.
models::pick() {
  local -a models
  models=("${(@f)$(models::discover)}")
  if (( ${#models} == 0 )) || [[ -z "${models[1]}" ]]; then
    ui::err "no .gguf models found"; return 1
  fi
  if ui::has fzf; then
    local sel
    sel=$(
      local m
      for m in "${models[@]}"; do printf '%s\t%s\n' "$(models::label "$m")" "$m"; done \
        | fzf --prompt='pick model: ' --no-sort --with-nth=1 --delimiter=$'\t' \
        | cut -f2
    )
    [[ -n "$sel" ]] || { ui::err "aborted"; return 1; }
    print -r -- "$sel"
  else
    local -a labels
    local m
    for m in "${models[@]}"; do labels+=("$(models::label "$m")") ; done
    local chosen idx
    chosen=$(ui::menu "pick model" "${labels[@]}") || return 1
    # Map chosen label back to its path by index.
    for (( idx = 1; idx <= $#labels; idx++ )); do
      [[ "${labels[idx]}" == "$chosen" ]] && { print -r -- "${models[idx]}"; return 0; }
    done
    return 1
  fi
}

# models::pull <repo[:quant]> -> download into the dedicated dir.
# Primary: hf CLI. Fallback: note that llama-server --hf-repo will fetch on start.
models::pull() {
  local repo="$1"
  [[ -n "$repo" ]] || { ui::err "usage: llmm pull <repo[:quant]>"; return 1; }
  local mdir="$(config::models_dir)"
  mkdir -p "$mdir"
  export HF_HOME="$mdir"
  if ui::has hf; then
    local name="${repo%%:*}" quant="${repo#*:}"
    if [[ "$quant" == "$repo" ]]; then
      ui::info "downloading $name (all files) into $mdir"
      hf download "$name"
    else
      ui::info "downloading $name (*$quant*.gguf) into $mdir"
      hf download "$name" --include "*${quant}*.gguf"
    fi
  else
    ui::warn "hf CLI not found; the server will download '$repo' via --hf-repo on first start (into $mdir)"
    return 0
  fi
}
