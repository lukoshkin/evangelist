#!/usr/bin/env bash

## TODO: Analyze files in directories specified in .xport-list.txt:
## - gather code and text files (with ext-s: .rs, .py, .txt and so on)
##   and those that are smaller than some threshold in MB and tar them.
## - write names of the rest files in a file, so a user can decide
##   themselves what to back up out of this collection.
## For this functionality, `save_analyze` and `load_analyze`
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

xport::save_all () {
  local bakdir=$1 baklist=$2
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

  tar xf "$bakdir/$name.tar.gz" --keep-newer-files -C "$prefix" \
    && echo "$file untar-ed successfully"
}

xport::load_all () {
local bakdir=$1 baklist=$2

  while read -r line; do
    _unpack "$line"
  done < "$baklist"
}
