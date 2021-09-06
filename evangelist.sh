#!/bin/bash

# Macros (ECHO, ECHO2, NOTE, HAS) are defined in _impl/write.sh

# Vim (8.1 and older) sources its rc file when running +PlugInstall.
# So, if dealing with Vim, we need to export the variables below.

export EVANGELIST=${EVANGELIST:-.}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-"$HOME/.cache"}
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
export XDG_DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}

source "$EVANGELIST/_impl/control.sh"
source "$EVANGELIST/_impl/install.bash4"
source "$EVANGELIST/_impl/write.sh"
source "$EVANGELIST/_impl/utils.sh"


main() {
  cd "$EVANGELIST"
  case $1 in
    install)        shift; control::install $@ ;;
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
  echo You may need to do a manual clean-up.
  cd - > /dev/null
  kill -9 $$
}


trap ctrl_c SIGINT
main $@

