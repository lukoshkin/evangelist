#!/bin/bash

## Macros (ECHO, ECHO2, NOTE, HAS) are defined in _impl/write.sh

## Vim (8.1 and older) sources its rc file when running +PlugInstall.
## So, if dealing with Vim, we need to export the variables below.

export EVANGELIST=${EVANGELIST:-.}
[[ -f evangelist.sh ]] && {
  ## If installing from the directory (probably moved or another one)
  export EVANGELIST=.
}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-"$HOME/.cache"}
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
export XDG_DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
export XDG_STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}

source "$EVANGELIST/_impl/control.sh"
source "$EVANGELIST/_impl/install.bash4"
source "$EVANGELIST/_impl/backup.sh"
source "$EVANGELIST/_impl/write.sh"
source "$EVANGELIST/_impl/utils.sh"


main() {
  local _EXTEND=false  # whether to install with extensions
  cd "$EVANGELIST" || { ECHO2 Failed to cd into $EVANGELIST; return; }
  ## No need to cd back in a child process.

  case $1 in
    install)        shift; control::install "$@" ;;
    install+)       shift; _EXTEND=true; control::install "$@" ;;

    save)           backup::save ;;
    load)           backup::load ;;

    update)         control::update $2 ;;
    reinstall)      control::reinstall $2 ;;
    uninstall)      control::uninstall ;;
    checkhealth)    control::checkhealth ;;
    --version)      control::version ;;
    *)              control::help ;;
  esac
}


ctrl_c () {
  NOTE 210 '\nInterrupted by user. Aborting..'
  echo 'You may need to do a manual clean-up.'
  kill -9 $$
}


trap ctrl_c SIGINT
main "$@"
