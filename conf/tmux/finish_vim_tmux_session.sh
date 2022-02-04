#!/usr/bin/env bash
## Original: https://github.com/ddelnano/tmux-vim-exit

__finish_vim_tmux_session() {
  tmux list-panes -F "#{pane_id} #{pane_current_command}" \
    | grep 'vim' | awk '/[0-9]+/{ print $1 }' \
    | while read paneId
  do
      tmux select-pane -t $paneId
      tmux send-keys ':update | qall'
      tmux send-keys Enter
  done
  tmux unlink-window -k
}


__finish_vim_tmux_session
