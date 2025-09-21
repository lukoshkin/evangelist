#!/usr/bin/env bash

# Source common autoenv functions
SCRIPT_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]:-$0}")")"
source "$SCRIPT_DIR/common.sh"

_venv_autoenv() {
  local _AE_EVNFILE

  # Use common function to process autoenv files
  if ! _process_autoenv_files "$1" "$2"; then
    # No marker files found, deactivate current venv if any
    if [[ -n "$VIRTUAL_ENV" ]]; then
      deactivate 2>/dev/null || true
    fi
    return 0
  fi

  local _env_ venv_path marker_dir
  _env_=${_AE_EVNFILE##*.}
  marker_dir=$(dirname "$_AE_EVNFILE")
  venv_path="$marker_dir/${_env_:-.venv}"

  if [[ ! -d "$venv_path" ]]; then
    echo "Not found venv directory: $venv_path"
    return 1
  fi

  if [[ ! -f "$venv_path/bin/activate" ]]; then
    echo "Not found venv activation script: $venv_path/bin/activate"
    return 1
  fi

  if [[ "$VIRTUAL_ENV" == "$venv_path" ]]; then
    if command -v deactivate &>/dev/null; then
      return 0
    fi
  fi

  if [[ -n "$VIRTUAL_ENV" ]]; then
    deactivate 2>/dev/null || true
  fi

  source "$venv_path/bin/activate"
}

_venv_autoenv_bash() {
  [[ "$PWD" = "$PREV_WORK_DIR" ]] && return
  _venv_autoenv "$PWD"
  PREV_WORK_DIR="$PWD"
}

_venv_autoenv_zsh() {
  _venv_autoenv "$PWD"
}

_mkenv_common() {
  local env_name=$1
  local use_seed=$2
  local venv_path=".venv"
  local use_uv=false

  if _command_exists uv; then
    echo "Detected uv package manager - using uv for faster operations"
    use_uv=true
  fi

  if [[ -n $env_name ]]; then
    venv_path="$env_name"
  fi

  local action_made
  action_made=Created
  if [[ -f ".autoenv-evn.$env_name" ]]; then
    action_made=Updated
  fi
  _remove_marker_files

  if [[ ! -d "$venv_path" ]]; then
    echo "Creating virtual environment: $venv_path"
    if [[ $use_uv == true ]]; then
      local uv_args=("$venv_path")
      if [[ $use_seed == true ]]; then
        echo "Using --seed option for Neovim integration"
        uv_args=("--seed" "${uv_args[@]}")
      fi
      uv venv "${uv_args[@]}" || {
        echo "Failed to create virtual environment with uv"
        return 1
      }
    else
      python3 -m venv "$venv_path" || {
        echo "Failed to create virtual environment"
        return 1
      }
    fi
  else
    echo "Virtual environment already exists: $venv_path"
    echo "To recreate, delete the directory and run the command again."
  fi

  source "$venv_path/bin/activate" || {
    echo "Failed to activate virtual environment"
    return 1
  }

  if [[ $use_uv == true && -f pyproject.toml ]]; then
    echo "Installing dependencies from pyproject.toml using uv..."
    uv sync || {
      echo "Failed to sync dependencies with uv"
      return 1
    }
  elif [[ -f requirements.txt ]]; then
    echo "Installing dependencies from requirements.txt..."
    if [[ $use_uv == true ]]; then
      uv pip install -r requirements.txt || {
        echo "Failed to install dependencies with uv"
        return 1
      }
    else
      pip install -r requirements.txt || {
        echo "Failed to install dependencies with pip"
        return 1
      }
    fi
  fi

  touch ".autoenv-evn.$env_name"
  echo "$action_made marker file: .autoenv-evn.$env_name"
}

mkenv() {
  _mkenv_common "$1" false
}

mkennv() {
  _mkenv_common "$1" true
}

# Setup shell hooks using common function
_setup_autoenv_hooks "_venv_autoenv_bash" "_venv_autoenv_zsh"
