#!/usr/bin/env bash
set -e

bakdir="$EVANGELIST/moving-over"
baklist="$EVANGELIST/xport.txt"

## TODO: Analyze files in directories specified in xport.txt:
## - gather code and text files (with ext-s: .rs, .py, .txt and so on)
##   and those that are smaller than some threshold in MB and tar them.
## - write names of the rest files in a file, so a user can decide
##   themselves what to back up out of this collection.
## For this functionality, `bakup_analyze` and `unpack_analyze`
## can be introduced.

_backup () {
  local file=$1 prefix name

  file=${line/#\~/$HOME}
  file=${file%/}
  prefix=$(dirname "$file")

  name=${file##*/}
  ! [[ -d $file ]] && { echo "Missing $line"; return; }
  tar czf "$bakdir/$name.tar.gz" -C "$prefix" "$name" \
    && echo "$file tar-ed successfully"
}

backup_all () {
  mkdir -p "$bakdir"

  while read -r line; do
    _backup "$line"
  done < "$baklist"
}

_unpack () {
  local file=$1 prefix name
  file=${line/#\~/$HOME}
  file=${file%/}
  prefix=$(dirname "$file")
  name=${file##*/}

  if ! [[ -e $bakdir/$name.tar.gz ]]; then
    echo "Missing $bakdir/$name.tar.gz"
    return
  fi

  tar xf "$bakdir/$name.tar.gz" -kC "$prefix" \
    && echo "$file untar-ed successfully"
}

unpack_all () {
  while read -r line; do
    _unpack "$line"
  done < "$baklist"
}

help_msg () {
  echo 'Backs up directories specified in xport.txt'
  echo 'Allowed commands: backup/unpack/help'
}


case "$1" in
  backup)  backup_all ;;
  unpack)  unpack_all ;;
  -h|help) help_msg ;;
  *)       echo "Unrecognized command: '$1'" ;;
esac
