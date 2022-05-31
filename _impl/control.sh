#!/bin/bash
## Shebang helps the editor to correctly render colors.

## Macros (ECHO, ECHO2, NOTE, HAS) are defined in _impl/write.sh

## About use of 'local' specifier in the code.
## There is no difference between using `local` or disregarding it,
## 1) if the function (which contains this `local`) is not sourced on
##    a shell startup, so the variable exists only within the script.
## 2) AND when declaring the variable at the top of the nested structure
##    of the function and its subroutine calls. While in subroutines,
##    we shadow the variable with `local` if want to reuse the name,
##    or prepend it to preserve the value.

## If met BOTH the conditions, there is no difference because being local
## at the top means being global at lower levels of the described hierarchy.


control::version () {
  echo -e "evangelist $(git describe --abbrev=0)\n"
  echo "Maintained by <lukoshkin@phystech.edu>"
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
  printf '  %-18s Update the repository and installed configs (beta).\n' 'update'
  printf '  %-18s Force update of the repository in case of merge conflicts.\n' 'reinstall'
  printf '  %-18s Roll back to the original settings.\n' 'uninstall'
  echo
}


control::checkhealth () {
  utils::get_installed_components

  if [[ -n $components ]]; then
    NOTE 147 "Installed: $components"
  else
    NOTE 147 'None of the listed configs is installed yet.'
  fi

  ## modulecheck's syntaxis: MODIFIER[l]:COMMAND[:PACKAGE][:VERSION]

  ## - MODIFIER is either 'r' (required), 'o' (optional), or '+' (extensions).
  ##   If modifier is used with l, COMMAND is considered to be a library,
  ##   and thus, is checked with HASLIB function.

  ## - COMMAND is a shell command that can be passed to
  ##   which/whence/type commands as argument.

  ## - PACKAGE is the name of an installation package
  ##   which contains the comannd. If the command name and
  ##   package name coincide, one can omit the latter.

  ## - VERSION is the minimal required version of a package.


  ## "Substitutable packages" or "a package and managers"
  ## that will install it in case of absence can be specified
  ## in a quoted space-separated string:

  ##     'nvim vim' (precedence to the 1st)
  ##         or
  ##     'nodejs conda' (nodejs can be installed via conda)

  ## If falling under the latter example, installation with the
  ## manager should be reflected in the code.

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
    o:'pip pip3':pip3 o:'nodejs conda':npm o:xclip \
    +:node::12.12 +l:libxcb-xinerama0 +:ninja:ninja-build
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

  ## 'local msg' below not only does shadow the eponymous variable in
  ## control::reinstall function (if `install` is invoked from there), but
  ## also makes `msg` empty, if the latter had any value before the statement.

  ## HOWEVER, feel the difference:
  ##   <.. in the body of some function ..>
  ##
  ##   msg=10                          local msg=10
  ##   local msg                       local msg
  ##   echo "<$msg>"  # prints <>      echo "<$msg>"  # prints <10>

  local msg _MSG shell=$(grep -oE '(z|ba)sh' <<< $@)
  ## UPPERCASE WITH LEADING UNDERSCORE show that the variable is exposed
  ## to subroutines, i.e. global to internal function calls.

  ## Let user select login shell
  if [[ $@ = *bash* ]] && [[ $@ = *zsh* ]]; then
    msg+="Since you are installing BOTH the shells' settings,\n"
    msg+='please type in which one will be used as a login shell.\n'

    NOTE 210 "$msg"
    read -p '(zsh|bash): ' shell
  fi

  ## Ensure shell settings are installed first
  declare -a params=$@
  [[ $@ = *bash+* ]] && params=( bash vim tmux ${params[@]/bash+} )
  [[ $@ = *zsh+* ]] && params=( zsh vim tmux ${params[@]/zsh+} )
  [[ $@ =~ bash ]] && params=( bash ${params[@]/bash} )
  [[ $@ =~ zsh ]] && params=( zsh ${params[@]/zsh} )

  ## Discard duplicates
  declare -a _PARAMS
  for arg in ${params[@]}
  do
    [[ ${_PARAMS[@]} =~ $arg ]] || _PARAMS+=( $arg )
  done
  set -- ${_PARAMS[@]}
  unset params

  for _ARG in $@; do
    case $_ARG in
      nvim|vim)    install::vim_settings ;;
      tmux)        install::tmux_settings ;;
      jupyter)     install::jupyter_settings ;;
      bash)        install::bash_settings ;;
      zsh)         install::zsh_settings ;;
      *)
        echo Impl.error: "<$_ARG>" should have thrown an error earlier.
        exit ;;
    esac

    [[ $? -ne 0 ]] && _PARAMS=( ${_PARAMS[@]/$_ARG} )
  done

  ## Set 1 next to successfully installed settings in `.update-list`.
  utils::update_status

  ## Don't print "further instructions" if installing non-interactively
  ## (e.g., when installing in a docker container).
  if [[ $TERM != dumb ]]; then
    write::instructions_after_install $shell
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
  for OBJ in $(sed '/nvim/d' <<< "$UPD"); do
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

          utils::v1_ge_v2 $(tmux -V | cut -d ' ' -f2) 3.1 \
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
    for OBJ in $(sed -n '/nvim/p' <<< "$UPD"); do
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
  if grep -q '^zsh' .update-list  # grep -q '^zsh:1' ?
  then
    ZDOTDIR=$(zsh -c 'echo $ZDOTDIR' 2> /dev/null)
    [[ -n "$ZDOTDIR" ]] && rm -rf "$ZDOTDIR"
    rm -f ~/.zshenv
  fi

  rm -f ~/.condarc
  rm -f ~/.tmux.conf
  if [[ -n "$XDG_CONFIG_HOME" ]]; then
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
  for OBJ in .bak/{*,.*}; do
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
  rm -rf .bak
}


control::reinstall () {
  HAS git || { ECHO2 Missing git; exit; }
  [[ -f .update-list ]] || { ECHO2 Missing '.update-list'.; exit; }
  assembly=$(grep 'VIM ASSEMBLY:' .update-list | cut -d ':' -f2)
  [[ $assembly = extended ]] && _EXTEND=-

  assembly=$(grep 'VIM ASSEMBLY:' .update-list | cut -d ':' -f2)
  [[ $assembly = extended ]] && _EXTEND=-

  utils::get_installed_components

  if [[ $1 = --no-reset ]]; then
    ECHO Reinstalling..

    control::install $components
    return
  fi

  msg+='By executing this command, all changes made to\n'
  msg+='the repository working tree will be lost. ABORT? [Y/n]\n'
  NOTE 210 "$msg"

  read -sn 1 -r
  ! [[ $REPLY = n ]] && { echo -e Aborted.; exit; }

  ECHO Reinstalling..

  git fetch -q || { echo Unable to fetch.; exit 1; }
  git reset --hard origin/$(git rev-parse --abbrev-ref HEAD)
  control::install $components
}
