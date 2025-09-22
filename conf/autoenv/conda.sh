#!/usr/bin/env bash

# Source common autoenv functions
SCRIPT_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]:-$0}")")"
source "$SCRIPT_DIR/common.sh"

_conda_autoenv() {
  local _AE_EVNFILE # result from _process_autoenv_files

  # Use common function to process autoenv files
  if ! _process_autoenv_files "$1" "$2"; then
    # No files found, activate base environment
    conda activate base
    return 0
  fi

  local _env_
  _env_=$(basename "$_AE_EVNFILE")
  _env_=${_env_#$AE_PREFIX}
  _env_=${_env_:-base} # for compatibility to be able to parse
  ## old .autoenv-evn files after switching to conda-autoenv from venv-autoenv

  [[ $CONDA_DEFAULT_ENV != "$_env_" ]] && conda activate "$_env_"
}

_conda_autoenv_bash() {
  [[ "$PWD" = "$PREV_WORK_DIR" ]] && return
  _conda_autoenv "$PWD"
  PREV_WORK_DIR="$PWD"
}

_conda_autoenv_zsh() {
  _conda_autoenv "$PWD"
}

mkenv() {
  if [[ -n $1 ]]; then
    conda activate "$1" || {
      echo "Create environment $1 first"
      return
    }
  fi

  if [[ -f environment.yml ]]; then
    local _env_
    echo "Found 'environment.yml'. Creating env from it.."
    _env_=$(
      grep '^name:' environment.yml |
        head -n1 | sed 's/name:[[:space:]]*//' | tr -d "\"'"
    )
    _remove_marker_files
    ( (conda env list | grep -q "^$_env_") ||
      conda env create -q -f environment.yml) &&
      conda activate "$_env_" &&
      touch ".autoenv-evn.$_env_"

  elif [[ $CONDA_DEFAULT_ENV != base ]]; then
    _remove_marker_files
    touch ".autoenv-evn.$CONDA_DEFAULT_ENV"
  fi
}

# Setup shell hooks using common function
_setup_autoenv_hooks "_conda_autoenv_bash" "_conda_autoenv_zsh"
