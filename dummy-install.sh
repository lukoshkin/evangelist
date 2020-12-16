#!/bin/bash
# WARNING: This is experimental set-up. Some lines may come and go.

[[ -z $XDG_CONFIG_HOME ]] && export XDG_CONFIG_HOME="$HOME/.config"
[[ -z $XDG_DATA_HOME ]] && export XDG_DATA_HOME="$HOME/.local/share"
[[ -z $XDG_CACHE_HOME ]] && export XDG_CACHE_HOME="$HOME/.cache"

# As you can see, the first 3 copies do not follow XDG concept.
# It might be fixed in further updates.
cp bash/bashrc ~/.bashrc
cp tmux.conf ~/.tmux.conf
cp bash/inputrc ~/.inputrc
cp -r nvim $XDG_CONFIG_HOME

[[ -n $(which conda) ]] && conda init bash

vimPlug="$XDG_DATA_HOME/nvim/site/autoload/plug.vim"
if [[ -f $vimPlug ]]; then
  sh -c 'curl -fLo $vimPlug --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
fi

vim +source $XDG_CONFIG_HOME/nvim/init.vim +q
vim +PlugInstall +qall


# PIP_FLAGS=(--no-cache-dir --upgrade)
# [[ -n $(which conda) ]] && {conda init bash; PIP_FLAGS+=(--user)

PIP_FLAGS=(--user --no-cache-dir --upgrade)

if [[ -z $JUPYTER_CONFIG_DIR ]]; then
  if [[ -d ~/.jupyter ]]
  then
    JUPYTER_CONFIG_DIR=~/.jupyter
  else
    pip install ${PIP_FLAGS[@]} --prefix $XDG_CONFIG_HOME jupyter
    JUPYTER_CONFIG_DIR=$XDG_CONFIG_HOME/jupyter
fi

pip install ${PIP_FLAGS[@]} \
  jupyter_contrib_nbextensions \
  jupyter_nbextensions_configurator

git clone https://github.com/lambdalisue/jupyter-vim-binding \
  $HOME/.local/share/jupyter/nbextensions/vim_binding && \
  jupyter nbextension enable vim_binding/vim_binding && \
  jupyter contrib nbextension install --user

rsync -a jupyter/custom.js $JUPYTER_CONFIG_DIR/custom/
cp jupyter/notebook.json $JUPYTER_CONFIG_DIR/nbconfig

[[ $EUID -eq 0 ]] && cp anacron/anacrontab.young /etc/anacrontab
