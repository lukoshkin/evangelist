#!/bin/sh
# This script is taken from post:
# https://blog.debiania.in.ua/posts/2012-07-31-purging-vim-undodir.html

# Purge vim's undodir (:help 'undodir', vim >= 7.3) from undofiles that does
# not have corresponding files in the filesystem anymore
#
# Intended to be called from crontab(1) job like that:
#
# # Purge undodir every week at 8:05AM
# 5 8 * * 1 /path/to/purgeVimUndo.sh /path/to/undo
# 
# Do not forget about the newline at the end of crontab file!

undodir="$1"

if [ -z "$undodir" ]
then
  echo "Path to undodir not specified." >&2
  exit 1
fi

if [ ! -d "$undodir" ]
then
  echo "Undodir ($undodir) does not exist (or isn't a directory)." >&2
  exit 2
fi

cd "$undodir"

for undofile in *
do
  filepath=`echo -n "$undofile" | sed 's#%#/#g'`
  if [ ! -e "$filepath" ]
  then 
    rm -f "$undofile"
  fi
done

cd - >/dev/null
