#!/bin/bash

## Macros (ECHO, ECHO2, NOTE, HAS) are defined in _impl/write.sh

## About coding style and 'local' in particular.
## No use of `local` specifier if variable does not appear
## in nested (internal) function calls, and the program finishes
## after this routine. Though the way 'local' being used may seem
## inconsistent in the project, it never leads to an error (I hope).

control::version () {
  echo evangelist $(git describe --abbrev=0)
  sed -n '3p' LICENSE
}


control::help () {
  echo 'Usage: ./evangelist.sh [opts] [<cmd> [<args>]]'
  echo An incorrect option or command will result in showing this message.
  echo -e '\nOptions:\n'
  printf '  %-18s Get the current version info.\n' '--version'

  echo -e '\nCommands:\n'
  printf '  %-18s Show the installation status or readiness to install.\n' 'checkhealth'
  printf '  %-18s Install one or all of the specified setups: bash zsh vim tmux jupyter.\n' 'install'
  printf '  %-18s Install with extensions if they are provided (beta). \n' 'install+'
  printf '  %-18s Update the repository and installed configs.\n' 'update'
  printf '  %-18s Force update of the repository in case of merge conflicts.\n' 'reinstall'
  printf '  %-18s Roll back to the original settings.\n' 'uninstall'
  echo
}


control::checkhealth () {
  components=$(sed '1,/Installed/d' .update-list 2> /dev/null | tr '\n' ' ')
  ## sed: comma specifies the operating range, where endpoints are included
  ## and can be patterns. If called without args, sed prints the current
  ## buffer. One can use $ as the EOF marker.

  if [[ -n $components ]]
  then
    NOTE 147 "Installed: $components"
  else
    NOTE 147 'None of the listed configs is installed yet.'
  fi

  ## modulecheck's syntaxis: MODIFIER:COMMAND[:PACKAGE]
  ## - MODIFIER is either 'r' (required) or 'o' (optional).
  ##
  ## - COMMAND is a shell command that can be passed to
  ## which/whence/type commands as argument.
  ##
  ## - PACKAGE is the name of an installation package
  ## which contains the comannd. If the command name and
  ## package name coincide, one can omit the latter.
  ##
  ## Substitutable packages or a package and managers
  ## that will install it in case of absence can be specified
  ## in a single-quoted space-separated string:
  ##     'nvim vim' (precedence to the 1st)
  ##         or
  ##     'npm conda' (npm can be installed via conda)

  BASH_DEPS=(o:conda o:tree)
  ZSH_DEPS=(r:zsh r:git o:conda o:fzf o:tree)

  [[ $(uname) != Darwin ]] \
    && ZSH_DEPS+=(o:transset:x11-apps)

  [[ -z $LANG ]] \
    && { BASH_DEPS+=(o:locale-gen:locales);
         ZSH_DEPS+=(r:locale-gen:locales); }

  write::modulecheck BASH ${BASH_DEPS[@]}
  write::modulecheck ZSH ${ZSH_DEPS[@]}
  write::modulecheck VIM \
    r:'nvim vim':neovim r:curl \
    o:'pip pip3':pip3 o:'npm conda':npm o:xclip
  write::modulecheck JUPYTER r:'pip pip3':pip3 r:git
  write::modulecheck TMUX r:tmux

  HAS conda || write::how_to_install_conda
}


control::install () {
  install::check_arguments $@

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

  ## 'local msg' not only does shadow the eponymous variable
  ## in control::reinstall function, but also makes `msg` empty,
  ## if the latter had any value before the statement.
  local msg _MSG _SHELL=$(grep -oE '(z|ba)sh' <<< $@)
  ## uppercase with leading underscore show that the variable is exposed
  ## to subroutines, i.e. global to internal function calls.

  ## Let user select login shell
  if [[ $@ = *bash* ]] && [[ $@ = *zsh* ]]
  then
    msg+="Since you are installing BOTH the shells' settings,\n"
    msg+='please type in which one will be used as a login shell.\n'

    NOTE 210 "$msg"
    read -p '(zsh|bash): ' _SHELL
  fi

  ## Ensure shell settings are installed first
  declare -a params=$@
  [[ $@ = *bash+* ]] && params=( bash vim tmux ${params[@]/bash+} )
  [[ $@ = *zsh+* ]] && params=( zsh vim tmux ${params[@]/zsh+} )
  [[ $@ =~ bash ]] && params=( bash ${params[@]/bash} )
  [[ $@ =~ zsh ]] && params=( zsh ${params[@]/zsh} )

  ## Discard duplicates
  declare -a newparams
  for arg in ${params[@]}
  do
    [[ ${newparams[@]} =~ $arg ]] || newparams+=( $arg )
  done
  set -- ${newparams[@]}
  unset params newparams

  while [[ $# -gt 0 ]]
  do
    case $1 in
      nvim|vim)    install::vim_settings; shift ;;
      tmux)        install::tmux_settings; shift ;;
      jupyter)     install::jupyter_settings; shift ;;
      bash)        install::bash_settings; shift ;;
      zsh)         install::zsh_settings; shift ;;
      *)           echo Infinite loop.; exit ;;
    esac
  done

  ## NOTE: if installing Vim configuration w/o shell settings,
  ## while both Vim and Neovim are available, `_SHELL` var changes
  ## from '' to "${SHELL##*/}" in vim_settings subroutine.
  if [[ $TERM != dumb ]] && [[ -n $_SHELL ]]
  then
    write::instructions_after_install $_SHELL
  fi
}


control::update () {
  HAS git || { ECHO2 Missing git; exit; }
  [[ -f .update-list ]] || { ECHO2 Missing '.update-list'.; exit; }

  [[ $1 != SKIP ]] && ECHO Checking for updates..

  git fetch -q
  local BRANCH UPD
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  UPD=$(git diff --name-only ..origin/$BRANCH)
  [[ -z "$UPD" ]] && { ECHO Up to date.; exit; }

  SRC=( evangelist.sh _impl )

  ## TODO: Add hook to handle updates that cannot be resolved
  ##       by the following code in the 'if'-statement.
  ## E.g.: If the structure of '.update-list' changes during development,
  ##       one must rewrite the file if it was generated
  ##       with old installation scripts.
  if [[ $1 != SKIP ]] && utils::str_has_any "$UPD" $SRC
  then
    ECHO Self-updating..

    git checkout origin/$BRANCH -- ${SRC[@]}

    $SHELL $0 update SKIP
    exit
  fi

  ECHO 'Updating installed components if any..'
  write::commit_messages $BRANCH
  git merge origin/$BRANCH || exit 1

  ## TODO: Rewrite 'case + if' to 'if + case' ? too cumbersome now
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
          sed "/>SED-UPDATE/,/<SED-UPDATE/{ />SED-UPDATE/r $OBJ
            d }" ~/.bashrc > /tmp/evangelist-bashrc
          mv /tmp/evangelist-bashrc ~/.bashrc
        fi
        ;;
        ## How sed works here. It applies the two commands to lines
        ## between >SED-UPDATE and <SED-UPDATE (including the markers):

        ## 1) insert file contents after >SED-UPDATE
        ## 2) delete all lines in the specified area

        ## Note, that no commands are applied to inserted text.

      zshenv)
        if grep -q '^zsh' .update-list
        then
          sed "/>SED-UPDATE/,/<SED-UPDATE/{ />SED-UPDATE/r $OBJ
            d }" ~/.zshenv > /tmp/evangelist-zshenv
          mv /tmp/evangelist-zshenv ~/.zshenv
        fi
        ;;

      tmux.conf)
        if grep -q '^tmux' .update-list
        then
          ## A more stable way to determine the version of Tmux:
          # TMUXV=$(tmux -V | sed -En 's/^tmux ([.0-9]+).*/\1/p')

          utils::dummy_v1_gt_v2 $(tmux -V | cut -d ' ' -f2) 3.1 \
            && cp $OBJ "$XDG_CONFIG_HOME/tmux" \
            || cp $OBJ ~/.${OBJ##*/}
            ## lstrip all the parents in dir name
        fi
        ;;

      custom.js)
        grep -q '^jupyter' .update-list \
          && cp $OBJ "$(jupyter --config-dir)"/custom/custom.js
        ;;

      notebook.json)
        grep -q '^jupyter' .update-list \
          && cp $OBJ "$(jupyter --config-dir)"/nbconfig/notebook.json
        ;;

      *)
        if [[ $OBJ =~ zsh/ ]] && grep -q '^zsh' .update-list
        then
          ZDOTDIR=$(zsh -c 'echo $ZDOTDIR')
          cp $OBJ "$ZDOTDIR"
        fi
        ;;
    esac
  done

  if grep -qE '^n?vim' .update-list
  then
    for OBJ in $(sed -n '/nvim/p' <<< "$UPD")
    do
      ## lstrip 'conf/' in names of the form 'conf/nvim/conf/...'
      cp $OBJ "$XDG_CONFIG_HOME/${OBJ#*/}"
    done
  fi

  ECHO Successfully updated.
}


control::uninstall () {
  [[ -d .bak ]] || { ECHO2 Missing '.bak'; exit; }
  [[ -f .update-list ]] || { ECHO2 Missing '.update-list'.; exit; }

  ECHO Uninstalling..

  grep -q '^bash' .update-list && rm ~/.{bashrc,inputrc}

  ## Completely eradicate the possibility of removing '/'
  if grep -q '^zsh' .update-list
  then
    ZDOTDIR=$(zsh -c 'echo $ZDOTDIR')
    [[ -n "$ZDOTDIR" ]] && rm -rf "$ZDOTDIR"
    rm -f ~/.zshenv
  fi

  rm -f ~/.condarc
  rm -f ~/.tmux.conf
  if [[ -n "$XDG_CONFIG_HOME" ]]
  then
    rm -rf "$XDG_CONFIG_HOME/nvim"
    rm -f "$XDG_CONFIG_HOME/tmux/.tmux.conf"
  fi

  if grep -q '^jupyter' .update-list
  then
    local JUPCONFDIR="$(jupyter --config-dir)"
    rm "$JUPCONFDIR/nbconfig/notebook.json"
    rm "$JUPCONFDIR/custom/custom.js"
  fi

  setopt nonomatch 2> /dev/null
  for OBJ in .bak/{*,.*}
  do
    case ${OBJ##*/} in
      .bashrc | .inputrc | .condarc | .zshenv | .zshrc | .tmux.conf)
        cp $OBJ ~
        ;;

      .vimrc)
        rm -f ~/.vimrc
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

  ECHO Successfully uninstalled.

  ## Check if necessary to change
  ## the login shell and Vim alternatives.
  write::instructions_after_removal
  rm .update-list
  rm -r .bak
}


control::reinstall () {
  HAS git || { ECHO2 Missing git; exit; }
  [[ -f .update-list ]] || { ECHO2 Missing '.update-list'.; exit; }
  assembly=$(grep 'VIM ASSEMBLY:' .update-list | cut -d ':' -f2)
  [[ $assembly = extended ]] && _EXTEND=-

  if [[ $1 = --no-reset ]]
  then
    control::install $(sed '1,/Installed/d' .update-list | tr '\n' ' ')
    return
  fi

  msg+='By executing this command, all changes made to\n'
  msg+='the repository working tree will be lost. ABORT? [Y/n]\n'
  NOTE 210 "$msg"

  read -sn 1 -r
  ! [[ $REPLY = n ]] && { echo -e Aborted.; exit 0; }

  ECHO Reinstalling..

  git fetch -q || { echo Unable to fetch.; exit 1; }
  git reset --hard origin/$(git rev-parse --abbrev-ref HEAD)
  control::install $(sed '1,/Installed/d' .update-list | tr '\n' ' ')
}
