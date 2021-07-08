#!/bin/bash

# Vim (8.1 and older) sources its rc file when running +PlugInstall.
# So, if dealing with Vim, we need to export the variables below.
export EVANGELIST=${EVANGELIST:-.}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-"$HOME/.cache"}
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
export XDG_DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}

source "$EVANGELIST/_impl/control-functions.sh"
source "$EVANGELIST/_impl/install-functions.sh"
source "$EVANGELIST/_impl/print-write.sh"
source "$EVANGELIST/_impl/utils.sh"


main() {
  cd "$EVANGELIST"
  case $1 in
    install)        shift; _install $@ ;;
    update)         _update $2 ;;
    reinstall)      _reinstall ;;
    uninstall)      _uninstall ;;
    checkhealth)    _checkhealth ;;
    --version)      _version ;;
    *) _help ;;
  esac
}


ctrl_c () {
  NOTE 210 '\nInterrupted by user. Aborting..'
  echo You may need to do a manual clean-up.
  cd - > /dev/null
  kill -9 $$
}


trap ctrl_c SIGINT
main $@
