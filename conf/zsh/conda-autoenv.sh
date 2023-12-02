#!/bin/bash

up_hierarchy_search() {
  if [[ -z $1 || -z $2 ]]
  then
    echo up_hierarchy_search: missing args.
    echo 'Try: up_hierarchy_search <dir> <file>`'
    return 1
  fi

  local found max_recursion_depth=100
  ## max_recursion_depth is for safety measures

  _up_hierarchy_search () {
    [[ $1 = / ]] && return 1
    ## 'ls $1/$2' is simpler but doesn't fit zsh
    ## (by default, zsh prints an error msg to stdout on a failed globbing).
    found=$(find "$1" -maxdepth 1 -type f -name "$2")

    if [[ -z $found ]] && [[ $max_recursion_depth -gt 0 ]]
    then
      (( max_recursion_depth-- ))
      _up_hierarchy_search "$(dirname "$1")" "$2"
    fi
  }

  local parent
  parent=$(realpath "$1" 2> /dev/null) \
    || parent=$(readlink -f "$1" 2> /dev/null) || return

  _up_hierarchy_search "$parent" "$2"
  echo "$found"
}


_conda_autoenv () {
  ## Disable conda-autoenv by setting AUENV_SHELL to false.
  ## Disabling functionality locally (or temporarily) may be useful
  ## when there is another plugin that temporarily takes care of managing
  ## conda environments.
  [[ $AUENV_SHELL == false ]] && return

  [[ -z $1 ]] && { echo Not enough args provided; return 1; }

  first_elem_id=${2:-1}
  local -a found=( "$(up_hierarchy_search "$1" '.autoenv-evn.*')" )

  if [[ -z ${found[*]} ]]
  then
    conda activate base
    return 0
  fi

  if [[ $(echo "${found[@]}" | wc -l) -gt 1 ]]
  then
    echo There are several autoenv-files found:
    echo ${found[*]}
    echo
    echo Note, the autoenv-script tries to activate only the environment
    echo 'corresponding to the first autoenv-file listed by `ls`.'
    echo Please, keep only one '.autoenv-evn.*'
    echo
  fi

  local file="${found[$first_elem_id]}" ENV
  ENV=${file##*.}

  ! [[ $CONDA_DEFAULT_ENV =~ $ENV ]] && conda activate $ENV
}


_conda_autoenv_bash() {
  [[ "$PWD" = "$PREV_WORK_DIR" ]] && return
  _conda_autoenv "$PWD" 0
  PREV_WORK_DIR="$PWD"
}

_conda_autoenv_zsh () {
  _conda_autoenv "$PWD"
}


mkenv () {
  if [[ -n $1 ]]
  then
    conda activate $1 || { echo "Create environment $1 first"; return; }
  fi

  if [[ -f environment.yml ]]; then
    echo "Found 'environment.yml'. Creating env from it.."
    local ENV=$(head -n 1 environment.yml | cut -d ' ' -f2)
    { command rm -rf .autoenv-evn.*; } 2> /dev/null
    ( (conda env list | grep -q "^$ENV") \
      || conda env create -q -f environment.yml ) \
        && conda activate $ENV \
        && touch .autoenv-evn.$ENV

  elif [[ $CONDA_DEFAULT_ENV != base ]]; then
    { command rm -rf .autoenv-evn.'*'; } 2> /dev/null
    touch .autoenv-evn.$CONDA_DEFAULT_ENV
  fi
}



if [[ ${HISTFILE##*/} =~ zsh ]]
then
  ## 'chpwd' hook fires when the directory is changed.
  autoload -U add-zsh-hook
  add-zsh-hook chpwd _conda_autoenv_zsh
  ## Run when starting a new shell instance.
  _conda_autoenv_zsh
elif [[ ${HISTFILE##*/} =~ bash ]]
then
  ## PROMPT_COMMAND contents is executed before each prompt.
  ## However, we want to be able to run `conda deactivate` in a directory
  ## with .autoenv-evn.* file. To this end, we use PREV_WORK_DIR variable
  ## to run the _conda_autoenv_zsh only when the directory is changed.

  ## To call _conda_autoenv_zsh on the shell startup, we initialize
  ## PREV_WORK_DIR with non-existent path
  PREV_WORK_DIR=/-/
  PROMPT_COMMAND="_conda_autoenv_bash; $PROMPT_COMMAND"
fi

