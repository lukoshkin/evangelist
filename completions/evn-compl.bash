#!/usr/env/bin bash

_evangelist () {
  opts=--version
  cmds='checkhealth install update reinstall uninstall'
  subcmds='zsh bash vim tmux jupyter'

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

    install)
      list=$subcmds;
      local -i maxopts=7
      # There are 5 options at max: bash zsh vim tmux jupyter.
      # Plus, command and program names (i.e., evangelist install ...).

      # If $line contains '+', the maximum number of options falls to 3
      # Plus, command and program names (i.e., evangelist install ...).
      [[ "${COMP_WORDS[@]}" = *'+'* ]] && maxopts=5
      [[ ${#COMP_WORDS[@]} -gt $maxopts ]] && return
      ;;

    *)
      [[ ${#COMP_WORDS[@]} -ge 3 ]] && return
      ;;
  esac

  # Negative indexing is available since bash 4.2.
  # For older versions, use `${arr[${#arr[@]-1}]}`.
  COMPREPLY=( $(compgen -W "$list" -- ${COMP_WORDS[-1]}) )
}

complete -F _evangelist evangelist
complete -F _evangelist evn
