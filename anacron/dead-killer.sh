#!/bin/sh
# This script is based on a snippet from the following post:
# https://blog.debiania.in.ua/posts/2012-07-31-purging-vim-undodir.html

PURGEDIR="$1"

if [ -z "$PURGEDIR" ]; then
  >&2 echo "Path to PURGEDIR not specified."
  exit 1
fi

if ! [ -d "$PURGEDIR" ]; then
  >&2 echo "Directory not found: PURGEDIR ($PURGEDIR)"
  exit 2
fi

cd "$PURGEDIR" || {
  echo "Cannot entry $PURGEDIR"
  exit 3
}
for file in *; do
  ## File path mangling is similar for undo and backup files.
  ## Except the latter ones have trailing char `~`.
  path=$(echo "$file" | sed 's#%#/#g')
  path=${path%\~}
  if [ ! -e "$path" ]; then
    rm -f "$file"
  fi
done
