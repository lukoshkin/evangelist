#!/bin/bash

# exploits:
# - print-write.sh
# - utils.sh

# NOTE: better to surround expansions with double quotes
# ####  if they might contain spaces.

check_arguments () {
  local allowed='bash+/zsh+, bash/zsh, nvim/vim, tmux, jupyter'

  if [[ $# -ne 0 ]]
  then
    local ok=true

    for arg in $@
    do
      [[ " $(tr ,/ ' ' <<< $allowed)" =~ " $arg" ]] || { ok=false; break; }
    done

    $ok && return
    echo -e "Invalid argument: $arg\n"
  fi

  echo 'Usage: ./evangelist.sh install <args>'
  echo Arguments: $allowed.
  echo
  echo zsh+ includes all settings except for bash and jupyter.
  echo Similarly, bash+ implies all but zsh and jupyter.
  echo 'nvim and vim arguments are identical for `install`.'
  exit
}


install_vim () {
  # Go on with Neovim if available, otherwise with Vim
  local VIM VIMPLUG
  local hint reply code=0

  # realpath is not available on OSX.
  # [[ $(realpath $(which vim)) =~ nvim ]] && (( code+=1 ))
  HAS vim && (( code+=1 ))
  HAS nvim && (( code+=2 ))

  [[ $code -eq 0 ]] && { ECHO2 Missing: vim, neovim; return; }
  ! grep -qE '^(ba|z)sh' .update-list
  code+="$?"

  # =========================================================================
  # NOTE: case fallthrough (;&) and resume (;;&) are available in bash >= 4.0
  # NOTE: zsh's 'case resume' is different - `;|`
  # NOTE: files backup is not implemented in this snippet

  # case $code in
  #   0)
  #     ECHO2 Missing: vim, neovim
  #     return
  #     ;;

  #   *)
  #     ECHO Installing Vim configuration..
  #     (! HAS pip && HAS pip3) && pip () { pip3 $@; }
  #     ;;&

  #   1?)
  #     VIM=vim
  #     VIMPLUG=~/.vim/autoload/plug.vim
  #     mkdir -p "$XDG_DATA_HOME/nvim/site/undo"
  #     ;;&

  #   [23]?)
  #     if ! HAS npm
  #     then
  #       echo Installing npm..
  #       conda install -yc conda-forge nodejs &> /dev/null \
  #         && echo - Installed nodejs. \
  #         || echo Failed to install: nodejs
  #     fi

  #     echo "Installing optional providers' deps.."
  #     ( npm ls -g | grep neovim || npm install -g neovim ) &> /dev/null \
  #       && echo - Installed neovim-client. \
  #       || echo "Cannot execute: npm install -g neovim"
  #     ( pip show pynvim || pip install pynvim ) &> /dev/null \
  #       && echo - Installed pynvim. \
  #       || echo "Cannot execute: pip install pynvim"

  #     VIM=nvim
  #     VIMPLUG="$XDG_DATA_HOME/nvim/site/autoload/plug.vim"
  #     ;;&

  #   ?0)
  #     # Check if need to expand $EVANGELIST
  #     sed -ri -e 's;\$EVANGELIST[.\"]*;'"$PWD"';' \
  #       -e 's;(filereadable\()(.+\));\1"\2;' \
  #       -e 's;\$XDG_CONFIG_HOME;'"$XDG_CONFIG_HOME"';' \
  #       "$XDG_CONFIG_HOME/nvim/init.vim"
  #     ;;&

  #   10)
  #     rm -f ~/.vimrc
  #     ln -s "$XDG_CONFIG_HOME"/nvim/init.vim ~/.vimrc
  #     ;;

  #   11)
  #     export MYVIMRC="$XDG_CONFIG_HOME/nvim/init.vim"
  #     export VIMINIT=":source $MYVIMRC"
  #     ;;

  #   30)
  #     case ${SHELL##*/} in
  #       bash) hint='~/.bashrc' ;;
  #       zsh) hint='$ZDOTDIR/.zshrc' ;;
  #     esac

  #     read -p "Where to add an alias? [$hint]: " reply
  #     [[ -z "$reply" ]] && reply=$(eval echo $hint)
  #     echo -e '\nalias nvim=vim # added by EVANGELIST' >> "$reply"
  #     # `shell` is local to `install` function
  #     # but accessible from `install_vim`.
  #     shell=${SHELL##*/}
  #     ;;

  #   2?) ;;
  #   *)
  #     ECHO2 "Implementation error: uncovered case."
  #     exit 1
  #     ;;
  # esac
  # =========================================================================

  ECHO Installing Vim configuration..

  # Make an "alias" for pip3
  (! HAS pip && HAS pip3) && pip () { pip3 $@; }

  case $code in
    1?)
      VIM=vim
      VIMPLUG=~/.vim/autoload/plug.vim
      mkdir -p "$XDG_DATA_HOME/nvim/site/undo"
      back_up_original_configs $VIM \
        f:~/.vimrc d:"$XDG_CONFIG_HOME/nvim"
      ;;

    [23]?)
      if ! HAS npm
      then
        echo Installing npm..
        conda install -yc conda-forge nodejs &> /dev/null \
          && echo - Installed nodejs. \
          || echo Failed to install: nodejs
      fi

      # Optional deps of Neovim providers (npm and python)
      echo "Installing optional providers' deps.."
      ( npm ls -g | grep neovim || npm install -g neovim ) &> /dev/null \
        && echo - Installed neovim-client. \
        || echo "Cannot execute: npm install -g neovim"
      ( pip show pynvim || pip install -q pynvim ) &> /dev/null \
        && echo - Installed pynvim. \
        || echo "Cannot execute: pip install pynvim"

      VIM=nvim
      VIMPLUG="$XDG_DATA_HOME/nvim/site/autoload/plug.vim"
      back_up_original_configs $VIM d:"$XDG_CONFIG_HOME/nvim"
      ;;
  esac

  # Copy new configs
  cp -R nvim "$XDG_CONFIG_HOME"

  if [[ $code = ?0 ]]
  then
  sed -ri -e 's;\$EVANGELIST[.\"]*;'"$PWD"';' \
    -e 's;(filereadable\()(.+\));\1"\2;' \
    -e 's;\$XDG_CONFIG_HOME;'"$XDG_CONFIG_HOME"';' \
    "$XDG_CONFIG_HOME/nvim/init.vim"
  fi

  case $code in
    10)
      rm -f ~/.vimrc
      ln -s "$XDG_CONFIG_HOME"/nvim/init.vim ~/.vimrc
      ;;

    11)
      export MYVIMRC="$XDG_CONFIG_HOME/nvim/init.vim"
      export VIMINIT=":source $MYVIMRC"
      ;;

    30)
      case ${SHELL##*/} in
        bash) hint='~/.bashrc' ;;
        zsh) hint='$ZDOTDIR/.zshrc' ;;
      esac

      read -p "Where to add an alias? [$hint]: " reply
      [[ -z "$reply" ]] && reply=$(eval echo $hint)
      echo -e '\nalias vim=nvim # added by EVANGELIST' >> "$reply"
      # TODO: Better use `update-alternatives` instead.

      # `shell` is local to `install` function
      # but accessible from `install_vim`.
      shell=${SHELL##*/}
      ;;

    2?) ;;
    *)
      ECHO2 "Implementation error: uncovered case."
      exit 1
      ;;
  esac

  # Install vim-plug if it is not there yet
  if [[ ! -f "$VIMPLUG" ]]; then
    sh -c "curl -sS -fLo $VIMPLUG --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
  fi

  # Install Vim plugins silently (save installation summary)
  $VIM +PlugInstall +'%w /tmp/vim-plug.log' +qa &> /dev/null

  if [[ -s /tmp/vim-plug.log ]]
  then
    echo Vim plugin installation summary:
    cat /tmp/vim-plug.log && rm -f /tmp/vim-plug.log
  fi

  ECHO Successfully installed: Vim configuration.
}


install_jupyter () {
  # Check if pip and git are available
  (HAS pip || HAS pip3) || { ECHO2 Missing pip3; exit; }
  HAS git || { ECHO2 Missing git; exit; }

  # Make an "alias" for pip3
  (! HAS pip && HAS pip3) && pip () { pip3 $@; }

  ECHO Installing Jupyter configuration..

  # Install Jupyter if necessary
  HAS jupyter \
    || { pip install -q jupyter \
         && HAS jupyter && echo Installed jupyter.; } \
      || { ECHO2 Jupyter is not accessible.; exit; }

  local JUPCONFDIR=$(jupyter --config-dir)

  back_up_original_configs jupyter \
    f:"$JUPCONFDIR/custom/custom.js" \
    f:"$JUPCONFDIR/nbconfig/notebook.json"

  # Install nbextensions if need be
  if ! pip show -qq jupyter_contrib_nbextensions
  then
    pip install -q jupyter_contrib_nbextensions \
      && echo Installed jupyter_contrib_nbextensions
  fi

  # Add extension tab in Jupyter Notebook if need be
  if ! pip show -qq jupyter_nbextensions_configurator
  then
    pip install -q jupyter_nbextensions_configurator \
      && echo Installed jupyter_nbextensions_configurator
  fi

  local JUPVIM="$(jupyter --data-dir)/nbextensions/vim_binding"
  [[ -d "$JUPVIM" ]] && rm -rf "$JUPVIM"

  # Install Vim for Jupyter Notebook
  git clone -q https://github.com/lambdalisue/jupyter-vim-binding "$JUPVIM"
  jupyter nbextension enable vim_binding/vim_binding  # add log lvl control?
  jupyter contrib nbextension install --user --JupyterApp.log_level='WARN'

  # Copy new configs
  mkdir -p "$JUPCONFDIR/custom"
  mkdir -p "$JUPCONFDIR/nbconfig"
  cp jupyter/custom.js "$JUPCONFDIR/custom"
  cp jupyter/notebook.json "$JUPCONFDIR/nbconfig"

  ECHO Successfully installed: Jupyter configuration.
}


install_tmux () {
  # Check if tmux is available
  HAS tmux || { ECHO2 Missing tmux; return; }

  ECHO Installing tmux configuration..

  back_up_original_configs tmux \
    f:~/.tmux.conf f:"$XDG_CONFIG_HOME/tmux/tmux.conf"

  # Version of tmux determines where to put tmux configs
  local VERSION=$(tmux -V | sed -En 's/^tmux ([.0-9]+).*/\1/p')

  # Copy new configs
  dummy_v1_gt_v2 $VERSION 3.1 \
    && cp -R tmux "$XDG_CONFIG_HOME" \
    || cp tmux/tmux.conf ~/.tmux.conf

  ECHO Successfully installed: Tmux configuration.
}


install_bash () {
  ECHO Installing BASH configuration..

  back_up_original_configs bash f:~/.bashrc f:~/.inputrc f:~/.condarc

  # Copy new configs
  cp bash/bashrc ~/.bashrc
  cp bash/inputrc ~/.inputrc

  make_descriptor ~/.bashrc

  # Add conda init to .bashrc
  conda &> /dev/null \
    && (conda init bash > /dev/null; conda config --set changeps1 False) \
    || ECHO2 "conda doesn't seem to work."

  dynamic_imports ~/.bashrc

  # Transfer the old history
  local NEWHISTFILE="$HOME/.bash_history"
  [[ -n "$HISTFILE" && "$HISTFILE" != "$NEWHISTFILE" ]] \
    && cp "$HISTFILE" "$NEWHISTFILE"

  ECHO Successfully installed: BASH configuration.
}


install_zsh () {
  # Check if zsh and git are available
  HAS zsh || { ECHO2 Missing zsh; exit; }
  HAS git || { ECHO2 Missing git; exit; }

  ECHO Installing ZSH configuration..

  # Set ZPLUG env vars
  [[ -z "$ZDOTDIR" ]] && export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
  [[ -z "$ZPLUG_HOME" ]] && export ZPLUG_HOME="$XDG_DATA_HOME/zplug"

  back_up_original_configs zsh \
    f:~/.zshenv f:~/.zshrc d:"$ZDOTDIR:zdotdir"

  mkdir -p "$ZDOTDIR"
  mkdir -p "$ZPLUG_HOME"

  # If there was no ~/.zshrc, remove it later
  # (BUG: conda init generates dummy .zshrc in $HOME ignoring $ZDOTDIR)
  ls ~/.zshrc &> /dev/null
  local CODE=$?

  # Copy new configs
  cp zsh/zshrc "$ZDOTDIR/.zshrc"
  cp zsh/agkozakrc "$ZDOTDIR"
  cp zsh/zshenv ~/.zshenv

  if [[ $(uname) == Darwin ]]
  then
    cp zsh/macos.zsh "$ZDOTDIR/extra.zsh"
  else
    cp zsh/extra.zsh "$ZDOTDIR"
  fi

  make_descriptor ~/.zshenv

  # Install zplug
  [[ ! -d "$ZPLUG_HOME/.git" ]] \
    && git clone -q https://github.com/zplug/zplug "$ZPLUG_HOME" \
    && echo Installed zplug.

  # Add conda init to .zshrc
  conda &> /dev/null \
    && conda init zsh > /dev/null \
    || ECHO2 "conda doesn't seem to work"

  # Deal with miniconda's bug
  grep -q '>>> conda init >>>' "$ZDOTDIR/.zshrc" \
    || sed -n '/> conda init/,/< conda init/p' \
         ~/.zshrc >> "$ZDOTDIR/.zshrc" 2> /dev/null

  [[ $CODE -gt 0 ]] && rm -f ~/.zshrc

  dynamic_imports "$ZDOTDIR/.zshrc"

  # Transfer the old history
  local NEWHISTFILE="$XDG_DATA_HOME/zsh_history"
  [[ -n "$HISTFILE" && "$HISTFILE" != "$NEWHISTFILE" ]] \
    && cp "$HISTFILE" "$NEWHISTFILE"

  ECHO Successfully installed: ZSH configuration.
}

