#!/bin/bash

# exploits: 
# - install-functions.sh
# - print-write.sh
# - utils.sh


_help () {
  echo -e "Usage: ./evangelist.sh [cmd] [args]\n"
  echo -e "Commands:\n"

  printf "  %-20s Update the repository and installed configs.\n" 'update'
  printf "  %-20s Install one of the specified setups: bash zsh jupyter.\n" 'install'
  printf "  %-20s Show the installation status or readiness to install.\n" 'checkhealth'
  printf "  %-20s Roll back to the original settings.\n" 'uninstall'
  printf "  %-20s Show this message and quit.\n" 'help'
}


_checkhealth () {
  if [[ ! -f 'update-list.txt' ]]
  then
    NOTE 147 "None of the listed configs is installed yet."
  else
    if [[ $(wc -l < update-list.txt) -gt 2 ]]
    then
      NOTE 147 "Installed: $(sed -n '3,$p' update-list.txt | tr '\n' ' ')"
    else
      NOTE 147 "None of the listed configs is installed yet."
    fi
  fi

  # modulecheck's syntaxis: MODIFIER:COMMAND[:PACKAGE]
  # - MODIFIER is either 'r' (required) or 'o' (optional).
  #
  # - COMMAND is a shell command that can be passed to
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
  #     'npm conda' (npm can be installed via conda)

  BASH_DEPS=(o:conda o:tree)
  ZSH_DEPS=(r:zsh r:git o:conda o:fzf o:tree)

  [[ $(uname) != Darwin ]] \
    && ZSH_DEPS+=(o:transset:x11-apps)

  [[ -z $LANG ]] \
    && { BASH_DEPS+=(o:locale-gen:locales);
         ZSH_DEPS+=(r:locale-gen:locales); }

  modulecheck BASH ${BASH_DEPS[@]}
  modulecheck ZSH ${ZSH_DEPS[@]}
  modulecheck VIM \
    r:'nvim vim':neovim r:curl \
    o:'pip pip3':pip3 o:'npm conda':npm
  modulecheck JUPYTER r:'pip pip3':pip3 r:git
  modulecheck TMUX r:tmux
}


_install () {
  # XDG specification
  [[ -z "$XDG_CONFIG_HOME" ]] && export XDG_CONFIG_HOME="$HOME/.config"
  [[ -z "$XDG_DATA_HOME" ]] && export XDG_DATA_HOME="$HOME/.local/share"
  [[ -z "$XDG_CACHE_HOME" ]] && export XDG_CACHE_HOME="$HOME/.cache"

  mkdir -p "$XDG_CONFIG_HOME"
  mkdir -p "$XDG_DATA_HOME"
  mkdir -p "$XDG_CACHE_HOME"

  mkdir -p .bak
  mkdir -p "$XDG_CONFIG_HOME"/evangelist/{bash,custom}

  touch update-list.txt
  if ! grep -q 'LOGIN-SHELL' update-list.txt
  then
    echo LOGIN-SHELL:${SHELL##*/} >> update-list.txt
    echo Installed components: >> update-list.txt
  fi

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


_update () {
  # Check the requirements
  # TODO: Print messages of pulled commits
  HAS git || { ECHO2 Missing git; exit; }
  [[ -f update-list.txt ]] || { ECHO2 Missing 'update-list.txt'.; exit; }

  [[ $1 != SKIP ]] && ECHO Checking for updates..

  git fetch -q
  local BRANCH UPD
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  UPD=$(git diff --name-only ..origin/$BRANCH)
  [[ -z "$UPD" ]] && { ECHO Up to date.; exit; }

  SRC='evangelist.sh _impl/*'

  # TODO: Add hook to handle updates that cannot be resolved
  # ####  by the following code in the 'if'-statement.
  # E.g.: If the structure of 'update-list.txt' changes during development,
  # ####  one must rewrite the file if it was generated with old installation scripts.
  if [[ $1 != SKIP ]] && str_has_any "$UPD" $SRC
  then
    ECHO Self-updating..

    git checkout origin/$BRANCH -- $SRC

    $SHELL $0 update SKIP
    exit
  fi

  ECHO 'Updating installed components if any..'
  git merge origin/$BRANCH || exit 1

  for OBJ in $(sed '/nvim/d' <<< "$UPD")
  do
    case ${OBJ##*/} in
      inputrc)
        grep -q '^bash' update-list.txt \
          && cp $OBJ ~
        ;;

      bashrc)
        if grep -q '^bash' update-list.txt
        then
          sed -e "/>SED-UPDATE/,/<SED-UPDATE/{ />SED-UPDATE/{p; r $OBJ
            }; /<SED-UPDATE/p; d }" ~/.bashrc > /tmp/evangelist-bashrc
          mv /tmp/evangelist-bashrc ~/.bashrc
        fi
        ;;

      zshenv)
        if grep -q '^zsh' update-list.txt
        then
          sed -e "/>SED-UPDATE/,/<SED-UPDATE/{ />SED-UPDATE/{p; r $OBJ
            }; /<SED-UPDATE/p; d }" ~/.zshenv > /tmp/evangelist-zshenv
          mv /tmp/evangelist-zshenv ~/.zshenv
        fi
        ;;

      aliases-functions.sh)
        grep -qE '^(ba|z)sh' update-list.txt \
          && cp $OBJ "$XDG_CONFIG_HOME/evangelist/bash"
        ;;

      ps1.bash)
        grep -q '^bash' update-list.txt \
          && cp $OBJ "$XDG_CONFIG_HOME/evangelist/bash"
        ;;

      tmux.conf)
        local TMUXV=$(tmux -V | sed -En 's/^tmux ([.0-9]+).*/\1/p')
        dummy_v1_gt_v2 $TMUXV 3.1 \
          && cp $OBJ "$XDG_CONFIG_HOME/tmux" \
          || cp $OBJ ~/.${OBJ##*/}
        ;;

      custom.js)
        grep -q '^jupyter' update-list.txt \
          && cp $OBJ $(jupyter --config-dir)/custom/custom.js
        ;;

      notebook.json)
        grep -q '^jupyter' update-list.txt \
          && cp $OBJ $(jupyter --config-dir)/nbconfig/notebook.json
        ;;

      *)
        ZDOTDIR=$(zsh -c 'echo $ZDOTDIR')
        [[ $OBJ =~ zsh ]] && grep -q '^zsh' update-list.txt \
          && cp $OBJ "$ZDOTDIR"
        ;;
    esac
  done

  for OBJ in $(sed -n '/nvim/p' <<< "$UPD")
  do
    cp $OBJ "$XDG_CONFIG_HOME/$OBJ"
  done

  ECHO Successfully updated.
}


_uninstall () {
  [[ -d .bak ]] || { ECHO2 Missing '.bak'; exit; }
  [[ -f update-list.txt ]] || { ECHO2 Missing 'update-list.txt'.; exit; }

  ECHO Uninstalling..

  grep -q '^bash' update-list.txt && rm ~/.{bashrc,inputrc}

  # Completely eradicate the possibility of removing '/'
  if grep -q '^zsh' update-list.txt
  then
    rm -f ~/.zshenv
    ZDOTDIR=$(zsh -c 'echo $ZDOTDIR')
    [[ -n "$ZDOTDIR" ]] && rm -rf "$ZDOTDIR"
  fi

  rm -rf "$XDG_CONFIG_HOME/nvim"
  rm -f ~/.condarc
  rm -f ~/.tmux.conf
  [[ -n "$XDG_CONFIG_HOME" ]] \
    && rm -f "$XDG_CONFIG_HOME/tmux/.tmux.conf"

  if grep -q '^jupyter' update-list.txt
  then
    local JUPCONFDIR=$(jupyter --config-dir)
    rm "$JUPCONFDIR/nbconfig/notebook.json"
    rm "$JUPCONFDIR/custom/custom.js"
  fi

  for OBJ in .bak/{*,.*}
  do
    case ${OBJ##*/} in
      .bashrc | .inputrc | .condarc | .zshenv | .zshrc | .tmux.conf)
        cp $OBJ ~
        ;;

      zdotdir)
        cp -R $OBJ/. "$ZDOTDIR"
        ;;

      nvim)
        cp -R $OBJ "$XDG_CONFIG_HOME"
        ;;

      tmux.conf)
        cp $OBJ "$XDG_CONFIG_HOME/tmux"
        ;;

      custom.js)
        cp $OBJ "$JUPCONFDIR/custom/custom.js"
        ;;

      notebook.json)
        cp $OBJ "$JUPCONFDIR/nbconfig/notebook.json"
        ;;

      *) :
        ;;
    esac
  done

  local LOGSHELL
  LOGSHELL=$(grep 'LOGIN-SHELL' update-list.txt | cut -d ':' -f2)

  rm update-list.txt
  rm -rf .bak

  ECHO Successfully uninstalled.

  # Check if necessary to change the login shell
  instructions_after_removal $LOGSHELL
}

