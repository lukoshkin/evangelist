#!/bin/bash
# WARNING: This is experimental set-up

if [[ -z $LUKOVNADOTFILES ]]; then
  cat bash/bashrc >> ~/.bashrc
  export LUKOVNADOTFILES="You are bash-vimmer now"
  [[ -z $XDG_CONFIG_HOME ]] && export XDG_CONFIG_HOME="$HOME/.config"
  [[ -z $XDG_DATA_HOME ]] && export XDG_DATA_HOME="$HOME/.local/share"
  [[ -z $XDG_CACHE_HOME ]] && export XDG_CACHE_HOME="$HOME/.cache"
fi

cp tmux.conf ~/.tmux.conf
cp bash/inputrc ~/.inputrc
cp -r nvim $XDG_CONFIG_HOME

vimPlug="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"
if [[ -f $vimPlug ]]; then
  sh -c 'curl -fLo $vimPlug --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
fi

vim +source $XDG_CONFIG_HOME/nvim/init.vim +q
vim +PlugInstall +qall
