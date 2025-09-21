#!/bin/bash

up_hierarchy_search() {
  if [[ -z $1 || -z $2 ]]; then
    echo up_hierarchy_search: missing args.
    echo 'Try: up_hierarchy_search <dir> <file>`'
    return 1
  fi

  ## `max_recursion_depth` to avoid infinite recursion
  local max_recursion_depth=100

  _up_hierarchy_search() {
    [[ $1 = / ]] && return 1
    ## 'ls $1/$2' is simpler but doesn't fit zsh
    ## (by default, zsh prints an error msg to stdout on a failed globbing).
    local found_evnfiles
    found_evnfiles=$(find "$1" -maxdepth 1 -type f -name "$2")

    if [[ -n $found_evnfiles ]] ||
      [[ $((max_recursion_depth--)) -le 0 ]]; then
      echo "$found_evnfiles"
      return
    fi

    _up_hierarchy_search "$(dirname "$1")" "$2"
  }

  local parent
  parent=$(realpath "$1" 2>/dev/null) ||
    parent=$(readlink -f "$1" 2>/dev/null) || return

  _up_hierarchy_search "$parent" "$2"
}

_conda_autoenv() {
  ## Disable conda-autoenv by setting AUENV_SHELL to false.
  ## Disabling functionality locally (or temporarily) may be useful
  ## when there is another plugin that temporarily takes care of managing
  ## conda environments.
  [[ $AUENV_SHELL == false ]] && return

  [[ -z $1 ]] && {
    echo Not enough args provided
    return 1
  }

  first_elem_id=${2:-1}
  local -a found=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && found+=("$line")
  done < <(up_hierarchy_search "$1" '.autoenv-evn.*')

  if [[ -z ${found[*]} ]]; then
    conda activate base
    return 0
  fi

  if [[ ${#found[@]} -gt 1 ]]; then
    echo There are several autoenv-files found:
    echo "${found[*]}"
    echo
    echo Note, the autoenv-script tries to activate only the environment
    echo "corresponding to the first autoenv-file listed by \`ls\`."
    echo Please, keep only one '.autoenv-evn.*'
    echo
  fi

  local file _env_
  file="${found[$first_elem_id]}"
  _env_=${file##*.}

  [[ $CONDA_DEFAULT_ENV != "$_env_" ]] && conda activate "$_env_"
}

_conda_autoenv_bash() {
  [[ "$PWD" = "$PREV_WORK_DIR" ]] && return
  _conda_autoenv "$PWD" 0
  PREV_WORK_DIR="$PWD"
}

_conda_autoenv_zsh() {
  if [[ -o KSH_ARRAYS ]]; then
    _conda_autoenv "$PWD" 0
  else
    _conda_autoenv "$PWD" 1
  fi
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
    { command rm -rf .autoenv-evn.*; } 2>/dev/null
    ( (conda env list | grep -q "^$_env_") ||
      conda env create -q -f environment.yml) &&
      conda activate "$_env_" &&
      touch ".autoenv-evn.$_env_"

  elif [[ $CONDA_DEFAULT_ENV != base ]]; then
    { command rm -rf .autoenv-evn.'*'; } 2>/dev/null
    touch ".autoenv-evn.$CONDA_DEFAULT_ENV"
  fi
}

if [[ -n $ZSH_VERSION ]]; then
  ## 'chpwd' hook fires when the directory is changed.
  autoload -U add-zsh-hook
  add-zsh-hook chpwd _conda_autoenv_zsh
  ## Run when starting a new shell instance.
  _conda_autoenv_zsh
elif [[ -n $BASH_VERSION ]]; then
  ## PROMPT_COMMAND contents is executed before each prompt.
  ## However, we want to be able to run `conda deactivate` in a directory
  ## with .autoenv-evn.* file. To this end, we use PREV_WORK_DIR variable
  ## to run the _conda_autoenv_zsh only when the directory is changed.

  ## To call _conda_autoenv_zsh on the shell startup, we initialize
  ## PREV_WORK_DIR with non-existent path
  PREV_WORK_DIR=/-/
  PROMPT_COMMAND="_conda_autoenv_bash; $PROMPT_COMMAND"
else
  >&2 echo 'Impl.error: autoenv works only with bash or zsh.'
fi
