#!/bin/bash

alias l='ls -lAh'
alias ll='ls -lh'
alias lt='ls -lAht'
alias md='mkdir -p'

alias _vimrc="vim $MYVIMRC"
alias vimrc="vim $XDG_CONFIG_HOME/evangelist/custom/custom.vim"

## Folder stack navigation
alias d='dirs -v'
alias G='gg 0'

gg () {
  if [[ -z $1 ]]
  then
    pushd +1 &> /dev/null
    [[ $? -ne 0 ]] && echo Singular dir stack || :
  elif [[ $1 == 0 ]]
  then
    pushd -0 > /dev/null
  elif [[ $1 =~ ^[0-9]+$ ]]
  then
    pushd +$1 > /dev/null
  elif [[ $1 =~ ^-[0-9]+$ ]]
  then
    popd +${1:1}
  else
    echo Wrong args
  fi
}


## Open the last file closed
# alias v="vim +'e #<1'"
alias v="vim +'execute \"normal \<C-P>\<Enter>\"'"
alias vv="vim +'browse filter !/__\|NERD_tree/ oldfiles'"

alias fd='find . -type d -name'
alias ff='find . -type f -name'
alias grep='grep --color'

tree () {
  command tree &> /dev/null || return

  local w8
  local hierarchy

  [[ -n $1 ]] && w8=$1 || w8=.1
  # 'script' preserves output colors (one of its assets)
  #  Since script saves the output to a file, /dev/null is used to discard it

  # -e - return exit code of the child process
  # -q - don't write start-end timestamps
  # -c - command to execute
  hierarchy=$(script -eqc "timeout --preserve-status $w8 tree" /dev/null)

  # 143 - SIGTERM (process was killed)
  if [[ $? -eq 143 ]]
  then
    echo 'Try to run it in one of subfolders.'
    return
  fi

  # double quotes are required in bash
  echo "$hierarchy"
}
