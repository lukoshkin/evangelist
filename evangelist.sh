#!/bin/bash

source print-functions.sh


main() {
  if [[ $1 == install ]]
  then
    _install $2
  elif [[ $1 == update ]]
  then
    _update $2
  elif [[ $1 == uninstall ]]
  then
    _uninstall
  elif [[ $1 == checkhealth ]]
  then
    _checkhealth
  else
    _help
  fi
}


_checkhealth () {
  if [[ ! -f 'update-list.txt' ]]
  then
    NOTE 147 "None of the listed configs is installed yet."
  else
    NOTE 147 "Installed: $(tr '\n' ' ' < update-list.txt)"
  fi

  # modulecheck's syntaxis: MODIFIER:COMMAND[:PACKAGE]
  # - MODIFIER is either 'r' (required) or 'o' (optional).
  #
  # - COMMAND is a shell command thah can be passed to
  # which/whence/type commands as argument.
  #
  # - PACKAGE is the name of an installation package
  # which contains the comannd. If the command name and
  # package name coincide, one can omit the latter.
  #
  # Substitutable packages or a package and managers
  # that will install it in case of absence can be specified
  # in a single-quoted space-separated string:
  #     'nvim vim' (precedence to the 1st)
  #         or
  #     'npm conda' (npm can be install via conda)

  BASH_DEPS=(o:conda o:tree)
  ZSH_DEPS=(r:zsh r:git o:conda o:fzf o:tree)

  [[ $(uname) != Darwin ]] \
    && ZSH_DEPS+=(o:transset:x11-apps)

  [[ -z $LANG ]] \
    && { BASH_DEPS+=(o:locale-gen:locales);
         ZSH_DEPS+=(r:locale-gen:locales); }

  [[ -z $1 || $1 == bash ]] \
    && modulecheck BASH ${BASH_DEPS[@]}
  [[ -z $1 || $1 == zsh ]] \
    && modulecheck ZSH ${ZSH_DEPS[@]}
  [[ -z $1 || $1 == vim ]] \
    && modulecheck VIM r:'nvim vim':neovim r:curl o:pip o:'npm conda'
  [[ -z $1 || $1 == notebook ]] \
    && modulecheck NOTEBOOK r:pip r:git
  [[ -z $1 || $1 == tmux ]] \
    && modulecheck TMUX r:tmux
}


_install () {
  # XDG specification
  [[ -z $XDG_CONFIG_HOME ]] && export XDG_CONFIG_HOME="$HOME/.config"
  [[ -z $XDG_DATA_HOME ]] && export XDG_DATA_HOME="$HOME/.local/share"
  [[ -z $XDG_CACHE_HOME ]] && export XDG_CACHE_HOME="$HOME/.cache"

  mkdir -p $XDG_CONFIG_HOME
  mkdir -p $XDG_DATA_HOME
  mkdir -p $XDG_CACHE_HOME
  mkdir -p .bak

  if [[ $1 == bash ]]
  then
    install_vim
    install_tmux
    install_bash
  elif [[ $1 == zsh ]]
  then
    install_vim
    install_tmux
    install_zsh
  elif [[ $1 == jupyter ]]
  then
    install_jupyter
  fi
}


install_vim () {
  # Check if neovim is available
  ( HAS nvim || HAS vim ) || { ECHO2 Missing: vim, neovim; return; }

  ECHO Installing Vim configuration...

  # Optional:
  # - npm (for some plugins and Neovim)
  # - python support (for Neovim)
  if HAS npm
  then
    conda install -yc conda-forge nodejs &> /dev/null \
    echo Installed nodejs.
  fi

  if HAS nvim
  then
    ( npm ls -g | grep neovim \
      || npm install -g neovim ) &> /dev/null \
      && echo Installed neovim-client. \
      || echo "Cannot execute: npm install -g neovim"
    ( pip show -qq pynvim \
      || pip install -q pynvim ) &> /dev/null \
      && echo Installed pynvim. \
      || echo "Cannot execute: pip install pynvim"
  fi

  # Back up original configs (just once)
  [[ -d $XDG_CONFIG_HOME/nvim ]] && cp -Rn $XDG_CONFIG_HOME/nvim .bak

  # Copy new configs
  cp -R nvim $XDG_CONFIG_HOME

  # Go on with Neovim if available, otherwise with Vim
  local VIM
  local VIMPLUG

  if HAS nvim
  then
    VIM=nvim
    VIMPLUG=$XDG_DATA_HOME/nvim/site/autoload/plug.vim
  elif HAS vim
  then
    VIM=vim
    VIMPLUG=~/.vim/autoload/plug.vim
    mkdir -p $XDG_DATA_HOME/nvim/site/undo
    export MYVIMRC=$XDG_CONFIG_HOME/nvim/init.vim
    export VIMINIT=":source $MYVIMRC"
  fi

  # Install vim-plug if it is not there yet
  if [[ ! -f $VIMPLUG ]]; then
    sh -c "curl -sS -fLo $VIMPLUG --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
  fi

  # Install Vim plugins
  $VIM +PlugInstall +qall

  add_entry_to_update_list $VIM

  ECHO Successfully installed: Vim configuration.
}


install_jupyter () {
  # Check if pip and git are available
  HAS pip || { ECHO2 Missing pip; exit; }
  HAS git || { ECHO2 Missing git; exit; }

  ECHO Installing Jupyter configuration...

  # Install Jupyter if necessary
  HAS jupyter \
    || { pip install -q jupyter \
         && HAS jupyter && echo Installed jupyter.; } \
      || { ECHO2 Jupyter is not accessible.; exit; }

  local JUPCONFDIR=$(jupyter --config-dir)

  # Back up original configs (just once)
  [[ -f $JUPCONFDIR/custom/custom.js ]] \
    && cp -n $JUPCONFDIR/custom/custom.js .bak
  [[ -f $JUPCONFDIR/nbconfig/notebook.json ]] \
    && cp -n $JUPCONFDIR/nbconfig/notebook.json .bak

  # Install nbextensions
  pip show -qq jupyter_contrib_nbextensions \
    || pip install -q jupyter_contrib_nbextensions \
    && echo Installed jupyter_contrib_nbextensions

  # Add extension tab in Jupyter Notebook 
  pip show -qq jupyter_nbextensions_configurator \
    || pip install -q jupyter_nbextensions_configurator \
    && echo Installed jupyter_nbextensions_configurator

  # Install Vim for Jupyter Notebook
  git clone -q https://github.com/lambdalisue/jupyter-vim-binding \
    $(jupyter --data-dir)/nbextensions/vim_binding
  jupyter nbextension enable vim_binding/vim_binding
  jupyter contrib nbextension install --user --JupyterApp.log_level='WARN'
  echo Enabled notebook extensions

  # Copy new configs
  mkdir -p $JUPCONFDIR/custom
  mkdir -p $JUPCONFDIR/nbconfig
  cp jupyter/custom.js $JUPCONFDIR/custom
  cp jupyter/notebook.json $JUPCONFDIR/nbconfig

  add_entry_to_update_list notebook

  ECHO Successfully installed: Jupyter configuration.
}


install_tmux () {
  # Check if tmux is available
  HAS tmux || { ECHO2 Missing tmux; return; }

  ECHO Installing tmux configuration...

  # Back up original configs (just once)
  [[ -f ~/.tmux.conf ]] \
    && cp -n ~/.tmux.conf .bak
  [[ -f $XDG_CONFIG_HOME/tmux/tmux.conf ]] \
    && cp -n $XDG_CONFIG_HOME/tmux/tmux.conf .bak

  # Version of tmux determines where to put tmux configs
  local VER=$(tmux -V | sed -En 's/^tmux ([.0-9]+).*/\1/p')
  local XDG=$(awk -v V=$VER 'BEGIN{if (V <= 3.1) print "1"; else print "0"}')

  # Copy new configs
  (( XDG )) \
    && cp tmux.conf ~/.tmux.conf \
    || { mkdir -p $XDG_CACHE_HOME/tmux; \
         cp tmux.conf $XDG_CACHE_HOME/tmux/tmux.conf; }

  add_entry_to_update_list tmux

  ECHO Successfully installed: Tmux configuration.
}


install_bash () {
  ECHO Installing BASH configuration...

  # Back up original configs (just once)
  [[ -f ~/.inputrc ]] && cp -n ~/.inputrc .bak
  [[ -f ~/.bashrc ]] && cp -n ~/.bashrc .bak

  # Copy new configs
  cp bash/bashrc ~/.bashrc
  cp bash/inputrc ~/.inputrc

  make_descriptor ~/.bashrc

  local CONDA
  # Add conda init to .bashrc 
  ( HAS conda && conda &> /dev/null ) \
    && { conda init bash > /dev/null && CONDA=A; } \
    || ECHO2 "conda doesn't seem to work"

  add_entry_to_update_list bash

  ECHO Successfully installed: BASH configuration.

  # Check if necessary to change the shell
  print_further_instructions_about bash $CONDA
}


install_zsh () {
  # Check if zsh and git are available
  HAS zsh || { ECHO2 Missing zsh; exit; }
  HAS git || { ECHO2 Missing git; exit; }

  ECHO Installing ZSH configuration...

  # Set ZPLUG env vars
  [[ -z $ZDOTDIR ]] && export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
  [[ -z $ZPLUG_HOME ]] && export ZPLUG_HOME="$XDG_DATA_HOME/zplug"

  mkdir -p $ZDOTDIR
  mkdir -p $ZPLUG_HOME

  # Back up original configs (just once)
  [[ -f ~/.zshenv ]] && cp -n ~/.zshenv .bak
  [[ -f ~/.zshrc ]] && cp -n ~/.zshrc .bak
  [[ -d $ZDOTDIR ]] && cp -Rn $ZDOTDIR .bak/zdotdir

  # Copy new configs
  cp zsh/zshrc $ZDOTDIR/.zshrc
  cp zsh/agkozakrc $ZDOTDIR
  cp zsh/zshenv ~/.zshenv

  HAS conda && cp zsh/conda_autoenv.sh $ZDOTDIR 

  if [[ $(uname) == Darwin ]]
  then
    cp zsh/macos.zsh $ZDOTDIR/extra.zsh
  else
    cp zsh/extra.zsh $ZDOTDIR
  fi

  make_descriptor ~/.zshenv

  # Install zplug
  [[ ! -d $ZPLUG_HOME/.git ]] \
    && git clone -q https://github.com/zplug/zplug $ZPLUG_HOME \
    && echo Installed zplug.

  local CONDA
  # Add conda init to .zshrc
  ( HAS conda && conda &> /dev/null ) \
    && { conda init zsh > /dev/null && CONDA=A; } \
    || ECHO2 "conda doesn't seem to work"

  add_entry_to_update_list zsh

  ECHO Successfully installed: ZSH configuration.

  # Check if necessary to change the shell
  print_further_instructions_about zsh $CONDA
}


_update () {
  # Check the requirements
  HAS git || { ECHO2 Missing git; exit; }
  [[ -f update-list.txt ]] || { ECHO2 Missing 'update-list.txt'.; exit; }

  [[ $1 != SKIP ]] && ECHO Checking for updates...

  git fetch -q
  UPD=$(git diff --name-only ..origin/develop)
  [[ -z $UPD ]] && { ECHO Up to date.; exit; }

  SRC='evangelist.sh print-functions.sh'

  if [[ $1 != SKIP ]] && str_has_any "$UPD" $SRC
  then
    ECHO Self-updating...

    git checkout origin/develop -- $SRC

    $SHELL $0 update SKIP
    exit
  fi

  ECHO 'Updating installed components if any...'
  git merge || exit 1

  for OBJ in $(echo $UPD | grep -v 'nvim'); do
    case ${OBJ##*/} in
      .bashrc | .inputrc)
        [[ -n $(grep bash update-list.txt) ]] \
          && cp $OBJ ~
        ;;

      .zshenv)
        [[ -n $(grep zsh update-list.txt) ]] \
          && cp $OBJ ~/.zshenv
        ;;

      tmux.conf)
        TMUXV=$(tmux -V | sed -En 's/^tmux ([.0-9]+).*/\1/p')
        [[ $TMUXV -le 3.1 ]] \
          && cp $OBJ ~/.${OBJ##*/} \
          || cp $OBJ $XDG_CONFIG_HOME/tmux
        ;;

      custom.js)
        [[ -n $(grep notebook update-list.txt) ]] \
          && cp $OBJ $(jupyter --config-dir)/custom/custom.js
        ;;

      notebook.json)
        [[ -n $(grep notebook update-list.txt) ]] \
          && cp $OBJ $(jupyter --config-dir)/nbconfig/notebook.json
        ;;

      *)
        ZDOTDIR=$(zsh -c 'echo $ZDOTDIR')
        [[ $OBJ =~ zsh && -n $(grep zsh update-list.txt) ]] \
          && cp $OBJ $ZDOTDIR
        ;;
    esac
  done

  for OBJ in $(echo $UPD | grep nvim); do
    cp $OBJ $XDG_CONFIG_HOME/$OBJ
  done

  ECHO Successfully updated.
}


_uninstall () {
  [[ -d .bak ]] || { ECHO2 "\n\tIt seems like the bakup folder was removed." \
    "\n\tIt also might have never been created on install."; exit; }
  [[ -f update-list.txt ]] || { ECHO2 Missing 'update-list.txt'.; exit; }

  ECHO Uninstalling...

  [[ -n $(grep bash update-list.txt) ]] \
    && rm ~/.{bashrc,inputrc}

  # Completely eradicate the possibility of removing '/'
  [[ -n $(grep zsh update-list.txt) ]] \
    && rm -f ~/.zshenv \
    && ZDOTDIR=$(zsh -c 'echo $ZDOTDIR') \
    && [[ -n $ZDOTDIR ]] && rm -rf $ZDOTDIR

  rm -rf $XDG_CONFIG_HOME/nvim

  rm -f ~/.tmux.conf
  [[ -n $XDG_CONFIG_HOME ]] \
    && rm -f $XDG_CONFIG_HOME/tmux/.tmux.conf

  [[ -n $(grep notebook update-list.txt) ]] \
    && { JUPCONFDIR=$(jupyter --config-dir);
         rm $JUPCONFDIR/custom/custom.js;
         rm $JUPCONFDIR/nbconfig/notebook.json; }

  for OBJ in .bak/* .bak/.*; do
    case ${OBJ##*/} in
      .bashrc | .inputrc | .zshenv | .zshrc | .tmux.conf)
        cp $OBJ ~
        ;;

      zdotdir)
        cp -a $OBJ/. $ZDOTDIR
        ;;

      nvim)
        cp -R $OBJ $XDG_CONFIG_HOME
        ;;

      tmux.conf)
        cp $OBJ $XDG_CONFIG_HOME/tmux
        ;;

      custom.js)
        cp $OBJ $JUPCONFDIR/custom/custom.js
        ;;

      notebook.json)
        cp $OBJ $JUPCONFDIR/nbconfig/notebook.json
        ;;

      *) :
        ;;
    esac
  done

  rm update-list.txt
  rm -rf .bak

  ECHO Successfully uninstalled.
  NOTE 210 'CLOSE YOUR CURRENT SHELL AND OPEN A NEW ONE.'
}



main $@
