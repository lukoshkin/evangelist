#!/bin/bash
# WARNING: This is experimental set-up

if [[ -z $LUKOVNADOTFILES ]]; then
  cat bash/bashrc >> ~/.bashrc
  export LUKOVNADOTFILES="I am bash-vimmer!"
  [[ -z $XDG_CONFIG_HOME ]] \
    && export XDG_CONFIG_HOME="$HOME/.config" \
    && echo 'export XDG_CONFIG_HOME="$HOME/.config"' >> ~/.bashrc
  [[ -z $XDG_DATA_HOME ]] \
    && export XDG_DATA_HOME="$HOME/.local/share" \
    && echo 'export XDG_DATA_HOME="$HOME/.local/share"' >> ~/.bashrc
  [[ -z $XDG_CACHE_HOME ]] \
    && export XDG_CACHE_HOME="$HOME/.cache" \
    && echo 'export XDG_CACHE_HOME="$HOME/.cache"' >> ~/.bashrc
fi

cp tmux.conf ~/.tmux.conf
cp bash/inputrc ~/.inputrc
cp -r nvim $XDG_CONFIG_HOME

vimPlug="$XDG_DATA_HOME/nvim/site/autoload/plug.vim"
if [[ -f $vimPlug ]]; then
  sh -c 'curl -fLo $vimPlug --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
fi

vim +source $XDG_CONFIG_HOME/nvim/init.vim +q
vim +PlugInstall +qall


if [[ -z $JUPYTER_CONFIG_DIR ]]; then
  if [[ -d ~/.jupyter ]]
  then
    JUPYTER_CONFIG_DIR=~/.jupyter
  else
    pip install --no-cache-dir --prefix $XDG_CONFIG_HOME --upgrade jupyter
    JUPYTER_CONFIG_DIR=$XDG_CONFIG_HOME/jupyter
fi

pip install --no-cache-dir \
  jupyter_contrib_nbextensions \
  jupyter_nbextensions_configurator

git clone https://github.com/lambdalisue/jupyter-vim-binding \
  $HOME/.local/share/jupyter/nbextensions/vim_binding && \
  jupyter nbextension enable vim_binding/vim_binding && \
  jupyter contrib nbextension install --user

rsync -a jupyter/custom.js $JUPYTER_CONFIG_DIR/custom/
cp jupyter/notebook.json $JUPYTER_CONFIG_DIR/nbconfig

[[ $EUID -eq 0 ]] && cp anacron/anacrontab.young /etc/anacrontab
