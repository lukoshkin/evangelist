#!/usr/env/bin bash

_evangelist() {
  opts=--version
  cmds='checkhealth install save load update reinstall uninstall'
  subcmds='zsh bash git vim tmux jupyter kitty systemd'

  list=$cmds

  # For older bash versions, this is better to use.
  # [[ ${COMP_WORDS[1]} =~ ^- ]] && list=$opts
  # [[ ${COMP_WORDS[1]} = --version ]] && return

  # [[ ${COMP_WORDS[1]} = install ]] && list=$subcmds \
  #   || { [[ ${#COMP_WORDS[@]} = 3 ]] && return; }

  # >= bash 4.0
  case ${COMP_WORDS[1]} in
  -*)
    list=$opts
    ;;&

  --version)
    return
    ;;

  update)
    list='--local'
    [[ ${#COMP_WORDS[@]} -gt 3 ]] && return
    ;;

  install)
    list=$subcmds
    local -i maxopts=10
    # There are 8 standalone options: bash zsh git vim tmux jupyter kitty systemd.
    # Plus, command and program names (i.e., evangelist install ...).

    # If line contains '+', the bundle covers git/vim/tmux/kitty, so only
    # jupyter and systemd remain as standalone extras (3 args max).
    [[ ${COMP_WORDS[*]} = *'+'* ]] && maxopts=6
    [[ ${#COMP_WORDS[@]} -gt $maxopts ]] && return
    ;;

  *)
    [[ ${#COMP_WORDS[@]} -ge 3 ]] && return
    ;;
  esac

  # Negative indexing is available since bash 4.2.
  # For older versions, use `${arr[${#arr[@]-1}]}`.
  COMPREPLY=($(compgen -W "$list" -- ${COMP_WORDS[-1]}))
}

complete -F _evangelist evangelist
complete -F _evangelist evn
