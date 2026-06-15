#!/usr/bin/env zsh
# config.zsh — locate/seed/source config, env precedence, profile + dir lookup.

config::reset_dirs() { :; }  # placeholder so callers can force re-eval; dirs are computed live.

config::config_home() { print -r -- "${XDG_CONFIG_HOME:-$HOME/.config}"; }
config::data_dir()    { print -r -- "${XDG_DATA_HOME:-$HOME/.local/share}/llmm"; }
config::state_dir()   { print -r -- "${XDG_STATE_HOME:-$HOME/.local/state}/llmm"; }
config::models_dir()  { print -r -- "$(config::data_dir)/models"; }
config::bin_dir()     { print -r -- "$(config::data_dir)/bin"; }
config::file()        { print -r -- "$(config::config_home)/llmm/config.zsh"; }

# config::pf <profile> <field> -> echoes LLMM_PROFILES[profile.field]
config::pf() { print -r -- "${LLMM_PROFILES[$1.$2]-}"; }

# config::seed -> copy the shipped default into the user config if absent.
config::seed() {
  local dst="$(config::file)" src="$LLMM_ROOT/config.default.zsh"
  [[ -f "$dst" ]] && return 0
  mkdir -p "${dst:h}"
  cp "$src" "$dst"
  ui::info "seeded config at $dst"
}

# config::load [path] -> source config with env vars taking precedence.
# Captures already-set LLMM_* env, sources the file, then re-applies the captures.
config::load() {
  local cfg="${1:-$(config::file)}"
  typeset -A _pre
  local v
  for v in ${(k)parameters[(I)LLMM_*]}; do
    # Only snapshot scalar env overrides; skip arrays/associations (e.g. LLMM_PROFILES),
    # which the config file owns and which can't round-trip through a scalar capture.
    [[ ${parameters[$v]} == *association* || ${parameters[$v]} == *array* ]] && continue
    _pre[$v]="${(P)v}"
  done
  [[ -f "$cfg" ]] && source "$cfg"
  for v in ${(k)_pre}; do typeset -g "$v"="${_pre[$v]}"; done
}
