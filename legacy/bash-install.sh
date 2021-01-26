#!/bin/bash

# Vim settings require XDG specification to be defined.
[[ -z $XDG_CONFIG_HOME ]] && export XDG_CONFIG_HOME="$HOME/.config"
[[ -z $XDG_DATA_HOME ]] && export XDG_DATA_HOME="$HOME/.local/share"
[[ -z $XDG_CACHE_HOME ]] && export XDG_CACHE_HOME="$HOME/.cache"

mkdir -p $XDG_CONFIG_HOME
mkdir -p $XDG_DATA_HOME
mkdir -p $XDG_CACHE_HOME

cp bash/bashrc ~/.bashrc
cp tmux.conf ~/.tmux.conf
cp bash/inputrc ~/.inputrc
cp -r nvim $XDG_CONFIG_HOME

which conda && conda init bash

vimPlug="$XDG_DATA_HOME/nvim/site/autoload/plug.vim"
if [[ ! -f $vimPlug ]]; then
  sh -c 'curl -fLo $vimPlug --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
fi

vim +source $XDG_CONFIG_HOME/nvim/init.vim +q
vim +PlugInstall +qall


# PIP_FLAGS=(--no-cache-dir --upgrade)
# which conda && conda init bash || PIP_FLAGS+=(--user)
PIP_FLAGS=(--user --no-cache-dir --upgrade)

which jupyter && \
  pip install ${PIP_FLAGS[@]} --prefix $XDG_CONFIG_HOME jupyter

pip install ${PIP_FLAGS[@]} \
  jupyter_contrib_nbextensions \
  jupyter_nbextensions_configurator

git clone https://github.com/lambdalisue/jupyter-vim-binding \
  $(jupyter --data-dir)/nbextensions/vim_binding && \
  jupyter nbextension enable vim_binding/vim_binding && \
  jupyter contrib nbextension install --user

mkdir -p $(jupyter --config-dir)/custom
mkdir -p $(jupyter --config-dir)/nbconfig
cp jupyter/custom.js $(jupyter --config-dir)/custom
cp jupyter/notebook.json $(jupyter --config-dir)/nbconfig

which anacron && sudo cp anacron/anacrontab.young /etc/anacrontab
