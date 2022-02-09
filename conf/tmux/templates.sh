#!/bin/bash
## Original: https://stackoverflow.com/questions/60330838

vip () {
  type vim &> /dev/null || { echo Neovim/Vim not found.; return 1; }
  type ipython &> /dev/null || { echo Ipython not found.; return 1; }

  [[ -z $1 ]] && vcmd='v' || vcmd="vim $1"
  [[ -n $TMUX ]] && { eval "$vcmd"; return; }

  icmd=ipython
  ## 'grep -qP' results in broken pipe error.
  ## So we use '> /dev/null' instead.
  ( pip3 --disable-pip-version-check list \
      | grep -P 'matplotlib(?!-inline)' > /dev/null ) \
    && icmd+=' --matplotlib' \
    || echo Install 'matplotlib' package for visualization.

  ## if there is no uuid
  uuid="$(uuidgen 2> /dev/null)"
  [[ -z $uuid ]] && uuid=vip

  tmux new -d -s "$uuid"
  tmux splitw -h -t "${uuid}:0.0"
  tmux send-keys -t "${uuid}.0" "$vcmd" ENTER
  tmux send-keys -t "${uuid}.1" "$icmd" ENTER
  tmux selectp -t "${uuid}.0"
  tmux a -t "$uuid"
}
