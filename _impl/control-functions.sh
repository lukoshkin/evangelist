#!/bin/bash

# exploits:
# - install-functions.sh
# - print-write.sh
# - utils.sh

_version () {
  echo evangelist $(git describe --abbrev=0)
  sed -n '3p' LICENSE
}


_help () {
  echo 'Usage: ./evangelist.sh [opts] [<cmd> [<args>]]'
  echo An incorrect option or command will result in showing this message.
  echo -e '\nOptions:\n'
  printf '  %-18s Get the current version info.\n' '--version'

  echo -e '\nCommands:\n'
  printf '  %-18s Update the repository and installed configs.\n' 'update'
  printf '  %-18s Install one or all of the specified setups: bash zsh vim tmux jupyter.\n' 'install'
  printf '  %-18s Show the installation status or readiness to install.\n' 'checkhealth'
  printf '  %-18s Roll back to the original settings.\n' 'uninstall'
  echo
}


_checkhealth () {
  if [[ ! -f '.update-list' ]]
  then
    NOTE 147 'None of the listed configs is installed yet.'
  else
    if [[ $(wc -l < .update-list) -gt 2 ]]
    then
      NOTE 147 "Installed: $(sed -n '3,$p' .update-list | tr '\n' ' ')"
    else
      NOTE 147 'None of the listed configs is installed yet.'
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
  check_arguments $@

  mkdir -p "$XDG_DATA_HOME"
  mkdir -p "$XDG_CACHE_HOME"
  mkdir -p "$XDG_CONFIG_HOME"

  mkdir -p .bak
  mkdir -p "$EVANGELIST/custom"

  touch .update-list
  if ! grep -q 'LOGIN-SHELL' .update-list
  then
    echo LOGIN-SHELL:${SHELL##*/} >> .update-list
    echo Installed components: >> .update-list
  fi

  # Let user select login shell
  local msg input=$(grep -oE '(z|ba)sh' <<< $@)
  if [[ $@ = *bash* && $@ = *zsh* ]]
  then
    msg+="Since you are installing BOTH the shells' settings,\n"
    msg+='please type in which one will be used as a login shell.\n'

    NOTE 210 "$msg"
    read -p '(zsh|bash): ' input
    echo
  fi

  # Ensure shell settings are installed first
  declare -a params=$@
  [[ $@ = *bash+* ]] && params=( bash vim tmux ${params[@]/bash+} )
  [[ $@ = *zsh+* ]] && params=( zsh vim tmux ${params[@]/zsh+} )
  [[ $@ =~ bash ]] && params=( bash ${params[@]/bash} )
  [[ $@ =~ zsh ]] && params=( zsh ${params[@]/zsh} )

  # Discard duplicates
  declare -a newparams
  for arg in ${params[@]}
  do
    [[ ${newparams[@]} =~ $arg ]] || newparams+=( $arg )
  done
  set -- ${newparams[@]}

  while [[ $# -gt 0 ]]
  do
    case $1 in
      vim) install_vim; shift ;;
      tmux) install_tmux; shift ;;
      jupyter) install_jupyter; shift ;;
      bash) install_bash; shift ;;
      zsh) install_zsh; shift ;;
      *) echo Infinite loop; exit ;;
    esac
  done

  [[ -n $input ]] && instructions_after_install $input
}


_update () {
  HAS git || { ECHO2 Missing git; exit; }
  [[ -f .update-list ]] || { ECHO2 Missing '.update-list'.; exit; }

  [[ $1 != SKIP ]] && ECHO Checking for updates..

  git fetch -q
  local BRANCH UPD
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  UPD=$(git diff --name-only ..origin/$BRANCH)
  [[ -z "$UPD" ]] && { ECHO Up to date.; exit; }

  SRC='evangelist.sh _impl/*'

  # TODO: Add hook to handle updates that cannot be resolved
  # ####  by the following code in the 'if'-statement.
  # E.g.: If the structure of '.update-list' changes during development,
  # ####  one must rewrite the file if it was generated with old installation scripts.
  if [[ $1 != SKIP ]] && str_has_any "$UPD" $SRC
  then
    ECHO Self-updating..

    git checkout origin/$BRANCH -- $SRC

    $SHELL $0 update SKIP
    exit
  fi

  ECHO 'Updating installed components if any..'
  print_commit_messages $BRANCH
  git merge origin/$BRANCH || exit 1

  for OBJ in $(sed '/nvim/d' <<< "$UPD")
  do
    case ${OBJ##*/} in
      inputrc)
        grep -q '^bash' .update-list \
          && cp $OBJ ~
        ;;

      bashrc)
        if grep -q '^bash' .update-list
        then
          sed -e "/>SED-UPDATE/,/<SED-UPDATE/{ />SED-UPDATE/r $OBJ
            d }" ~/.bashrc > /tmp/evangelist-bashrc
          mv /tmp/evangelist-bashrc ~/.bashrc
        fi
        ;;
        # How sed works here. It applies the two commands to lines
        # between >SED-UPDATE and <SED-UPDATE (including the markers):

        # 1) insert file contents after >SED-UPDATE
        # 2) delete all lines in the specified area

        # Note, that no commands are applied to inserted text.

      zshenv)
        if grep -q '^zsh' .update-list
        then
          sed -e "/>SED-UPDATE/,/<SED-UPDATE/{ />SED-UPDATE/r $OBJ
            d }" ~/.zshenv > /tmp/evangelist-zshenv
          mv /tmp/evangelist-zshenv ~/.zshenv
        fi
        ;;

      tmux.conf)
        local TMUXV=$(tmux -V | sed -En 's/^tmux ([.0-9]+).*/\1/p')
        dummy_v1_gt_v2 $TMUXV 3.1 \
          && cp $OBJ "$XDG_CONFIG_HOME/tmux" \
          || cp $OBJ ~/.${OBJ##*/}
        ;;

      custom.js)
        grep -q '^jupyter' .update-list \
          && cp $OBJ $(jupyter --config-dir)/custom/custom.js
        ;;

      notebook.json)
        grep -q '^jupyter' .update-list \
          && cp $OBJ $(jupyter --config-dir)/nbconfig/notebook.json
        ;;

      *)
        ZDOTDIR=$(zsh -c 'echo $ZDOTDIR')
        [[ $OBJ =~ zsh ]] && grep -q '^zsh' .update-list \
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
  [[ -f .update-list ]] || { ECHO2 Missing '.update-list'.; exit; }

  ECHO Uninstalling..

  grep -q '^bash' .update-list && rm ~/.{bashrc,inputrc}

  # Completely eradicate the possibility of removing '/'
  if grep -q '^zsh' .update-list
  then
    ZDOTDIR=$(zsh -c 'echo $ZDOTDIR')
    [[ -n "$ZDOTDIR" ]] && rm -rf "$ZDOTDIR"
    rm -f ~/.zshenv
  fi

  rm -rf "$XDG_CONFIG_HOME/nvim"
  rm -f ~/.condarc
  rm -f ~/.tmux.conf
  [[ -n "$XDG_CONFIG_HOME" ]] \
    && rm -f "$XDG_CONFIG_HOME/tmux/.tmux.conf"

  if grep -q '^jupyter' .update-list
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
    esac
  done

  local LOGSHELL
  LOGSHELL=$(grep 'LOGIN-SHELL' .update-list | cut -d ':' -f2)

  rm .update-list
  rm -rf .bak

  ECHO Successfully uninstalled.

  # Check if necessary to change the login shell
  instructions_after_removal $LOGSHELL
}

