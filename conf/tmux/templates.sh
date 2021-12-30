#!/bin/bash
# Original: https://stackoverflow.com/questions/60330838

vip () {
  type vim &> /dev/null || { echo Neovim/Vim not found.; return 1; }
  type ipython &> /dev/null || { echo Ipython not found.; return 1; }

  [[ -z $1 ]] && cmd='v' || cmd="vim $1"
  [[ -n $TMUX ]] && { eval "$cmd"; return; }

  uuid="$(uuidgen)"
  tmux new -d -s "$uuid"
  tmux splitw -h -t "${uuid}:0.0"
  tmux send-keys -t "${uuid}.0" "$cmd" ENTER
  tmux send-keys -t "${uuid}.1" "ipython --matplotlib" ENTER
  tmux selectp -t "${uuid}.0"
  tmux a -t "$uuid"
}
