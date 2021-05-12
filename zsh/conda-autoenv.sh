#!/bin/bash

_conda_autoenv_zsh() {
  first_elem_id=${1:-1}

  local lsout code
  { ls .autoenv-evn.*; } &> /dev/null
  code=$?

  if [[ $code -ne 0 ]]
  then
    # Note: [[ "sth" =~ "" ]] evaluates to 'true'
    ! [[ "$PWD" =~ "$CONDA_AUTOENV" ]] \
      && CONDA_AUTOENV= && conda deactivate
    return 0
  fi

  lsout=( $(ls .autoenv-evn.*) )
  if [[ ${#lsout[@]} -gt 1 ]]
  then
    echo There are several autoenv-files found: ${lsout[@]}
    echo Note, the autoenv-script will try to activate only the environment
    echo 'corresponding to the first autoenv-file listed by `ls`.'
    echo Please, keep only one '.autoenv-evn.*'
    echo
  fi

  local file=${lsout[$first_elem_id]} ENV
  ENV=${file##*.}

  # Check if you are already in the environment.
  # (conda modifies $PATH every time the environment changes.)
  # CONDA_AUTOENV prevents 'base` from getting deactivated.
  ! [[ $PATH =~ $ENV ]] && conda activate $ENV && CONDA_AUTOENV="$PWD"
}


_conda_autoenv_bash() {
  [[ "$PWD" = "$PREV_WORK_DIR" ]] && return
  _conda_autoenv_zsh 0
  PREV_WORK_DIR="$PWD"
}


mkenv () {
  if [[ -n $1 ]]
  then
    conda activate $1 || return
  fi

  if [[ $CONDA_DEFAULT_ENV != base ]]
  then
    CONDA_AUTOENV=$CONDA_DEFAULT_ENV
    rm -rf .autoenv-evn.*
    touch .autoenv-evn.$CONDA_AUTOENV

  elif [[ -f environment.yml ]]
  then
    local ENV
    ENV=$(head -n 1 environment.yml | cut -d ' ' -f2)
    { rm -rf .autoenv-evn.*; } 2> /dev/null
    ( (conda env list | grep -q "^$ENV") \
      || conda env create -q -f environment.yml ) \
        && conda activate $ENV \
        && CONDA_AUTOENV=$ENV \
        && touch .autoenv-evn.$ENV
  fi
}



if [[ ${HISTFILE##*/} =~ zsh ]]
then
  # 'chpwd' hook fires when the directory is changed.
  autoload -U add-zsh-hook
  add-zsh-hook chpwd _conda_autoenv_zsh
  # Run when starting a new shell instance.
  _conda_autoenv_zsh
elif [[ ${HISTFILE##*/} =~ bash ]]
then
  # PROMPT_COMMAND contents is executed before each prompt.
  # However, we want to be able to run `conda deactivate` in a directory
  # with .autoenv-evn.* file. To this end, we use PREV_WORK_DIR variable
  # to run the _conda_autoenv_zsh only when the directory is changed.

  # To call _conda_autoenv_zsh on the shell startup, we initialize
  # PREV_WORK_DIR with non-existent path
  PREV_WORK_DIR=/-/
  PROMPT_COMMAND="_conda_autoenv_bash; $PROMPT_COMMAND"
fi

