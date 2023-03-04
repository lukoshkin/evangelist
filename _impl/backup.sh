#!/bin/bash

source "$EVANGELIST/_impl/xport.sh"
source "$EVANGELIST/_impl/bak-keys.sh"

_BAKDIR="$EVANGELIST/moving-over"
_BAKLIST="$EVANGELIST/.xport-list.txt"

_checks () {
  [[ -d ${1:-$_BAKDIR} ]] || { echo 'Missing backup directory'; exit 1; }
  [[ -f $_BAKLIST ]] || { echo 'Missing backup list'; exit 1; }
}

backup::save () {
  _checks "$1"

  set -e
  keys::save "${1:-$_BAKDIR}"
  xport::save_all "${1:-$_BAKDIR}" "$_BAKLIST"
}

backup::load () {
  _checks "$1"

  set -e
  keys::load "${1:-$_BAKDIR}"
  xport::load_all "${1:-$_BAKDIR}" "$_BAKLIST"
}
