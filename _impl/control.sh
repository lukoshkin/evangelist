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

control::version() {
  echo -e "evangelist $(git describe --abbrev=0)\n"
  echo "Maintained by <lukoshkin.workspace@gmail.com>"
  sed -n '3p' LICENSE
}

control::help() {
  echo 'Usage: ./evangelist.sh [opts] [<cmd> [<args>]]'
  echo An incorrect option or command will result in showing this message.
  echo -e '\nOptions:\n'
  printf '  %-18s Get the current version info.\n' '--version'

  echo -e '\nCommands:\n'
  printf '  %-18s Show the installation status or readiness to install.\n' 'checkhealth'
  printf '  %-18s Install one or all of the specified setups: bash zsh git vim tmux jupyter kitty hammerspoon systemd.\n' 'install [--clean]'
  printf '  %-18s Install with extensions if they are provided (beta).\n' 'install+'
  printf '  %-18s Update the repository and installed configs.\n' 'update'
  printf '  %-18s Force update of the repository in case of merge conflicts.\n' 'reinstall'
  printf '  %-18s Roll back to the original settings.\n\n' 'uninstall'

  printf '  %-18s Save files specified in .xport-list before moving over (beta).\n' 'save'
  printf '  %-18s Unpack what you brought using `save` command (beta).\n' 'load'
  echo
}

control::checkhealth() {
  local components
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
  VIM_DEPS=(
    r:'nvim vim':neovim r:curl
    o:'pip pip3':pip3 o:'node nodejs conda':npm
    +:node:node:12.12 +:ninja:ninja +:rg:ripgrep +:cmake:cmake
  )
  GIT_DEPS=(r:git o:delta)

  if utils::is_macos; then
    VIM_DEPS+=(o:pbcopy +:fd:fd +:xelatex:mactex +:cc:'Xcode Command Line Tools')
    GIT_DEPS=(r:git o:delta:git-delta)
  else
    ZSH_DEPS+=(o:transset:x11-apps)
    VIM_DEPS+=(o:xclip +l:libxcb-xinerama0 +:fd-find:fd-find +:xelatex:texlive-xetex +:gcc:build-essential)
  fi

  [[ -z $LANG ]] && utils::is_linux &&
    {
      BASH_DEPS+=(o:locale-gen:locales)
      ZSH_DEPS+=(r:locale-gen:locales)
    }

  write::modulecheck BASH "${BASH_DEPS[@]}"
  write::modulecheck ZSH "${ZSH_DEPS[@]}"
  write::modulecheck VIM "${VIM_DEPS[@]}"
  ## Many plugins require node (particularly CoC).
  ## `nvim-treesitter` wants gcc compiler, `telescope-fzf-native` wants CMake.
  ## Clipboard, fd, and LaTeX package names differ between Linux and macOS.
  write::modulecheck JUPYTER r:'pip pip3':pip3 r:git
  write::modulecheck TMUX r:tmux
  write::modulecheck GIT "${GIT_DEPS[@]}"
  write::modulecheck KITTY o:kitty
  utils::is_macos && write::modulecheck HAMMERSPOON o:hs:hammerspoon
  utils::is_linux && write::modulecheck SYSTEMD r:systemctl r:sudo o:oomctl

  HAS conda || write::how_to_install_conda
}

control::install() {
  ## Parse --clean flag before argument validation.
  _CLEAN=false
  if [[ "$*" == *--clean* ]]; then
    _CLEAN=true
    set -- "${@/--clean/}"
  fi

  ## Extract --mode/--tool/--force (used only by the `ai` component)
  ## before the component-argument munging below can swallow them.
  ## Mirrors --clean.
  _AI_MODE=""
  _AI_TOOL=""
  _AI_FORCE=false
  local -a _rest=()
  while [[ $# -gt 0 ]]; do
    case $1 in
    --mode) _AI_MODE="${2:-}"; shift 2 ;;
    --mode=*) _AI_MODE="${1#*=}"; shift ;;
    --tool) _AI_TOOL="${2:-}"; shift 2 ;;
    --tool=*) _AI_TOOL="${1#*=}"; shift ;;
    --force) _AI_FORCE=true; shift ;;
    *) _rest+=("$1"); shift ;;
    esac
  done
  set -- "${_rest[@]}"

  install::check_arguments "$@"

  mkdir -p "$XDG_DATA_HOME"
  mkdir -p "$XDG_CACHE_HOME"
  mkdir -p "$XDG_CONFIG_HOME"
  mkdir -p "$XDG_STATE_HOME"
  ## It seems like Neovim does not require manual creation of the latter.
  ## Most likely, more recent versions of Neovim.

  mkdir -p .bak
  mkdir -p "$EVANGELIST/custom"

  if ! [[ -f .xport-list.txt ]]; then
    echo "$EVANGELIST" >.xport-list.txt
    echo "$HOME/.ssh" >>.xport-list.txt
  fi

  touch .update-list
  if ! grep -q 'LOGIN-SHELL' .update-list; then
    echo LOGIN-SHELL:${SHELL##*/} >>.update-list
    echo Installed components: >>.update-list
  fi

  ## Preserve assembly mode on re-install (same as control::reinstall).
  if ! $_EXTEND; then
    local assembly
    assembly=$(grep 'VIM ASSEMBLY:' .update-list | cut -d ':' -f2)
    [[ $assembly =~ (extended|neovim-lua) ]] && _EXTEND=true
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

  local msg _MSG shell=$(grep -oE '(z|ba)sh' <<<"$@")
  ## UPPERCASE WITH LEADING UNDERSCORE show that the variable is exposed
  ## to subroutines, i.e. global to internal function calls.

  ## Let user select login shell
  if [[ $* = *bash* ]] && [[ $* = *zsh* ]]; then
    msg+="Since you are installing BOTH the shells' settings,\n"
    msg+='please type in which one will be used as a login shell.\n'

    NOTE 210 "$msg"
    read -p '(zsh|bash): ' shell
  fi

  ## Ensure shell settings are installed first
  declare -a params=("$@")
  [[ $* = *bash+* ]] && params=(bash git vim tmux kitty "${params[@]/bash+/}")
  [[ $* = *zsh+* ]] && params=(zsh git vim tmux kitty "${params[@]/zsh+/}")
  [[ $* =~ bash ]] && params=(bash "${params[@]/bash/}")
  [[ $* =~ zsh ]] && params=(zsh "${params[@]/zsh/}")

  ## Discard duplicates
  declare -a _PARAMS
  for arg in "${params[@]}"; do
    [[ ${_PARAMS[*]} =~ $arg ]] || _PARAMS+=("$arg")
  done
  set -- "${_PARAMS[@]}"
  unset params

  for _ARG in "$@"; do
    case $_ARG in
    nvim | vim) install::vim_settings ;;
    tmux) install::tmux_settings ;;
    jupyter) install::jupyter_settings ;;
    bash) install::bash_settings ;;
    zsh) install::zsh_settings ;;
    git) install::git_settings ;;
    kitty) install::kitty_settings ;;
    hammerspoon) install::hammerspoon_settings ;;
    systemd) install::systemd_settings ;;
    ai) install::ai_settings ;;
    *)
      echo Impl.error: "<$_ARG>" should have thrown an error earlier.
      exit
      ;;
    esac

    [[ $? -ne 0 ]] && _PARAMS=("${_PARAMS[@]/$_ARG/}")
  done

  ## Set 1 next to successfully installed settings in `.update-list`.
  utils::update_status

  ## Don't print "further instructions" if installing non-interactively
  ## (e.g., when installing in a docker container).
  if [[ $TERM != dumb ]]; then
    ${_SHELL_RESET:-false} && shell=
    write::instructions_after_install $shell
  fi
}

## Update installed configs from the remote repository.
control::update() {
  HAS git || {
    ECHO2 Missing git
    exit
  }
  [[ -f .update-list ]] || {
    ECHO2 Missing '.update-list'.
    exit
  }

  [[ $1 != SKIP ]] && ECHO Checking for updates..

  git fetch -q
  local BRANCH UPD
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  UPD=$(git diff --name-only ..origin/"$BRANCH")
  [[ -z "$UPD" ]] && {
    ECHO Up to date.
    exit
  }

  SRC=(evangelist.sh _impl)

  ## TODO: Add hook to handle updates that cannot be resolved
  ##       by the following code in the 'if'-statement.
  ## E.g.: If the structure of '.update-list' changes during development,
  ##       one must rewrite the file if it was generated
  ##       with old installation scripts.
  if [[ $1 != SKIP ]] && utils::str_has_any "$UPD" "${SRC[@]}"; then
    ECHO Self-updating..

    git checkout "origin/$BRANCH" -- "${SRC[@]}"

    $SHELL "$0" update SKIP
    exit
  fi

  ECHO 'Updating installed components if any..'
  write::commit_messages "$BRANCH"
  git merge "origin/$BRANCH" || exit 1

  ## TODO: Rewrite 'case + if' to 'if + case' ? too cumbersome now
  for OBJ in $(sed '/nvim/d' <<<"$UPD"); do
    case ${OBJ##*/} in
    inputrc)
      grep -q '^bash' .update-list &&
        cp $OBJ ~
      ;;

    bashrc)
      if grep -q '^bash' .update-list; then
        sed "/>SED-UPDATE/,/<SED-UPDATE/{ />SED-UPDATE/r $OBJ
            d }" ~/.bashrc >/tmp/evangelist-bashrc
        mv /tmp/evangelist-bashrc ~/.bashrc
      fi
      ;;
      ## How sed works here. It applies the two commands to lines
      ## between >SED-UPDATE and <SED-UPDATE (including the markers):

      ## 1) insert file contents after >SED-UPDATE
      ## 2) delete all lines in the specified area

      ## Note, that no commands are applied to inserted text.

    zshenv)
      if grep -q '^zsh' .update-list; then
        sed "/>SED-UPDATE/,/<SED-UPDATE/{ />SED-UPDATE/r $OBJ
            d }" ~/.zshenv >/tmp/evangelist-zshenv
        mv /tmp/evangelist-zshenv ~/.zshenv
      fi
      ;;

    tmux.conf)
      if grep -q '^tmux' .update-list; then
        ## A more stable way to determine the version of Tmux:
        # TMUXV=$(tmux -V | sed -En 's/^tmux ([.0-9]+).*/\1/p')

        utils::v1_ge_v2 $(tmux -V | cut -d ' ' -f2) 3.1 &&
          cp $OBJ "$XDG_CONFIG_HOME/tmux" ||
          cp $OBJ ~/.${OBJ##*/}
        ## lstrip all the parents in dir name
      fi
      ;;

    custom.js)
      grep -q '^jupyter' .update-list &&
        cp $OBJ "$(jupyter --config-dir)"/custom/custom.js
      ;;

    notebook.json)
      grep -q '^jupyter' .update-list &&
        cp $OBJ "$(jupyter --config-dir)"/nbconfig/notebook.json
      ;;

    *)
      if [[ $OBJ =~ kitty/ ]] && grep -q '^kitty' .update-list; then
        mkdir -p "$XDG_CONFIG_HOME/kitty"
        cp $OBJ "$XDG_CONFIG_HOME/kitty/"
      elif [[ $OBJ =~ hammerspoon/ ]] && grep -q '^hammerspoon' .update-list; then
        mkdir -p "$HOME/.hammerspoon"
        cp $OBJ "$HOME/.hammerspoon/"
      elif [[ $OBJ =~ zsh/ ]] && grep -q '^zsh' .update-list; then
        ZDOTDIR=$(zsh -c 'echo $ZDOTDIR')
        cp $OBJ "$ZDOTDIR"
      fi
      ;;
    esac
  done

  ## Only re-apply when actual install inputs changed. README, apply.sh,
  ## setup-zram.sh edits are doc-only / manual-path-only and shouldn't
  ## trigger a sudo prompt and an oomd restart.
  if utils::is_linux \
    && grep -qE '^conf/systemd/(files/|launchers/|setup-app-priorities\.sh)' <<<"$UPD" \
    && grep -q '^systemd' .update-list; then
    install::systemd_settings
  fi

  if grep -qE '^conf/ai/' <<<"$UPD" && grep -q '^ai' .update-list; then
    ECHO 'Refreshing AI-assistant config..'
    local ai_state="${XDG_STATE_HOME:-$HOME/.local/state}/evangelist"
    local ai_mode ai_tool
    ai_mode=$(cat "$ai_state/ai-mode" 2>/dev/null || echo 1)
    ai_tool=$(cat "$ai_state/ai-tool" 2>/dev/null || echo all)
    bash "$EVANGELIST/conf/ai/install.sh" "$ai_mode" "$ai_tool"
  fi

  if grep -qE '^n?vim' .update-list; then
    local assembly
    assembly=$(grep 'VIM ASSEMBLY:' .update-list | cut -d ':' -f2)

    ## Clear old config files before re-copying (prevents stale files).
    ## Only affects $XDG_CONFIG_HOME/nvim (configs), not $XDG_DATA_HOME (plugin data).
    rm -rf "$XDG_CONFIG_HOME/nvim"
    cp -R conf/nvim "$XDG_CONFIG_HOME"

    if [[ $assembly == neovim-lua ]]; then
      cd "$XDG_CONFIG_HOME/nvim" &&
        rm -rf lua &&
        mv edge/{lua,init.lua} . &&
        rm -rf init.vim edge &&
        cd - >/dev/null ||
        echo '- [ERR] Failed to restructure nvim-lua config.'
    fi

    echo '- [OK] Nvim configs updated.'
    echo '- [INFO] Run :Lazy sync in Neovim to update plugins.'
  fi

  ECHO Successfully updated.
  ## Enforce printing further instructions.
  _PARAMS=$shell write::instructions_after_install $shell
}

control::uninstall() {
  [[ -d .bak ]] || {
    ECHO2 Missing '.bak'
    exit
  }
  [[ -f .update-list ]] || {
    ECHO2 Missing '.update-list'.
    exit
  }

  ECHO Uninstalling..

  grep -q '^bash' .update-list && rm ~/.{bashrc,inputrc}

  ## Completely eradicate the possibility of removing '/'
  if grep -q '^zsh' .update-list; then # grep -q '^zsh:1' ?
    ZDOTDIR=$(zsh -c 'echo $ZDOTDIR' 2>/dev/null)
    [[ -n "$ZDOTDIR" ]] && rm -rf "$ZDOTDIR"
    rm -f ~/.zshenv
  fi

  grep -qE '^(bash|zsh)' .update-list && rm -f ~/.condarc
  rm -f ~/.tmux.conf
  if [[ -n "$XDG_CONFIG_HOME" ]]; then
    ## Unlikely there will be /nvim and /tmux dirs, nevertheless..
    rm -rf "$XDG_CONFIG_HOME/nvim"
    rm -f "$XDG_CONFIG_HOME/tmux/.tmux.conf"
  fi

  if utils::is_linux; then
    rm -f "$XDG_DATA_HOME/applications/nvim.desktop"
  fi
  if utils::is_linux && HAS xdg-mime; then
    local current
    current=$(xdg-mime query default text/plain)
    if [[ "$current" == nvim.desktop ]]; then
      local fallback
      for fallback in org.gnome.TextEditor.desktop xed.desktop mousepad.desktop kate.desktop; do
        if [[ -f "/usr/share/applications/$fallback" ]]; then
          xdg-mime default "$fallback" text/plain
          xdg-mime default "$fallback" text/markdown
          xdg-mime default "$fallback" application/json
          break
        fi
      done
    fi
  fi

  if grep -qE '^n?vim' .update-list; then
    rm -rf "$XDG_DATA_HOME/nvim"
    rm -rf "$XDG_DATA_HOME/mason"
  fi

  if grep -q '^git' .update-list; then
    git config --global --unset core.pager 2>/dev/null
    git config --global --unset interactive.diffFilter 2>/dev/null
  fi

  local JUPCONFDIR=""
  if grep -q '^jupyter' .update-list; then
    JUPCONFDIR="$(jupyter --config-dir)"
    rm -f "$JUPCONFDIR/nbconfig/notebook.json"
    rm -f "$JUPCONFDIR/custom/custom.js"
  fi

  if grep -q '^kitty' .update-list; then
    rm -rf "$XDG_CONFIG_HOME/kitty"
  fi

  if grep -q '^hammerspoon' .update-list; then
    rm -rf "$HOME/.hammerspoon"
  fi

  if utils::is_linux && grep -q '^systemd' .update-list; then
    ECHO Reverting systemd OOM hardening..
    NOTE 210 'Removing drop-ins under /etc/ — sudo will prompt for your password.'
    sudo rm -f \
      /etc/systemd/oomd.conf.d/override.conf \
      /etc/systemd/system/-.slice.d/10-oomd.conf \
      /etc/systemd/system/user@.service.d/10-oomd.conf \
      /etc/systemd/system/system.slice.d/10-oomd.conf \
      /etc/sysctl.d/99-swap.conf

    ## Restore originals if any were captured (usually none — the drop-ins
    ## did not exist before install).
    [[ -f .bak/systemd-oomd-override.conf ]] && sudo install -D -m 0644 \
      .bak/systemd-oomd-override.conf /etc/systemd/oomd.conf.d/override.conf
    [[ -f .bak/systemd-slice-10-oomd.conf ]] && sudo install -D -m 0644 \
      .bak/systemd-slice-10-oomd.conf /etc/systemd/system/-.slice.d/10-oomd.conf
    [[ -f .bak/systemd-user-10-oomd.conf ]] && sudo install -D -m 0644 \
      .bak/systemd-user-10-oomd.conf /etc/systemd/system/user@.service.d/10-oomd.conf
    [[ -f .bak/systemd-systemslice-10-oomd.conf ]] && sudo install -D -m 0644 \
      .bak/systemd-systemslice-10-oomd.conf /etc/systemd/system/system.slice.d/10-oomd.conf
    [[ -f .bak/sysctl-99-swap.conf ]] && sudo install -D -m 0644 \
      .bak/sysctl-99-swap.conf /etc/sysctl.d/99-swap.conf

    sudo systemctl daemon-reload
    sudo systemctl restart systemd-oomd 2>/dev/null
    sudo sysctl --system >/dev/null

    ## Drop the marker-tagged .desktop overrides written by
    ## conf/systemd/setup-app-priorities.sh (chrome/slack/spotify/telegram
    ## and the protected terminals).
    local USER_APPS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
    if [[ -d "$USER_APPS_DIR" ]]; then
      local f
      for f in "$USER_APPS_DIR"/*.desktop; do
        [[ -f "$f" ]] || continue
        head -n1 "$f" | grep -q 'Generated by evangelist (oom-priority)' &&
          rm -f "$f"
      done
      command -v update-desktop-database >/dev/null &&
        update-desktop-database "$USER_APPS_DIR" 2>/dev/null
    fi

    ## Drop the marker-tagged user-level systemd drop-ins (e.g.
    ## gnome-terminal-server.service.d/10-oomd.conf).
    local USER_SYSD_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
    if [[ -d "$USER_SYSD_DIR" ]]; then
      local d sysd_changed=false
      for d in "$USER_SYSD_DIR"/*.service.d; do
        [[ -d "$d" ]] || continue
        local drop="$d/10-oomd.conf"
        if [[ -f "$drop" ]] &&
          head -n1 "$drop" | grep -q 'Generated by evangelist (oom-priority)'; then
          rm -f "$drop"
          rmdir "$d" 2>/dev/null
          sysd_changed=true
        fi
      done
      $sysd_changed && systemctl --user daemon-reload 2>/dev/null
    fi
  fi

  if grep -q '^ai' .update-list; then
    ECHO 'Removing AI-assistant config..'
    local item tool manifest f
    for item in commands skills scripts CLAUDE.md statusline.sh settings.json; do
      [[ -L "$HOME/.claude/$item" ]] && rm -f "$HOME/.claude/$item"
      [[ -e "$HOME/.claude/$item.pre-evangelist.bak" ]] &&
        mv "$HOME/.claude/$item.pre-evangelist.bak" "$HOME/.claude/$item"
    done
    for tool in codex copilot cursor; do
      manifest="$HOME/.$tool/.convert-manifest"
      [[ -f "$manifest" ]] || continue
      while IFS= read -r f; do
        [[ -n "$f" ]] || continue
        [[ -d "$f" ]] && rm -rf "$f" || rm -f "$f"
      done <"$manifest"
      rm -f "$manifest"
    done
  fi

  setopt nonomatch 2>/dev/null
  for OBJ in .bak/{*,.*}; do
    case ${OBJ##*/} in
    .bashrc | .inputrc | .condarc | .zshenv | .zshrc | .gitconfig | .tmux.conf)
      cp $OBJ ~
      ;;

    .vimrc)
      rm -f ~/.vimrc
      cp $OBJ ~
      ;;

    zdotdir)
      cp -R $OBJ/. "$ZDOTDIR"
      ;;

    git*)
      cp -R $OBJ ~/.config
      ;;

    nvim)
      cp -R $OBJ "$XDG_CONFIG_HOME"
      ;;

    tmux.conf)
      cp $OBJ "$XDG_CONFIG_HOME/tmux"
      ;;

    kitty)
      cp -R $OBJ "$XDG_CONFIG_HOME"
      ;;

    .hammerspoon)
      cp -R $OBJ ~
      ;;

    custom.js)
      [[ -n $JUPCONFDIR ]] && cp $OBJ "$JUPCONFDIR/custom/custom.js"
      ;;

    notebook.json)
      [[ -n $JUPCONFDIR ]] && cp $OBJ "$JUPCONFDIR/nbconfig/notebook.json"
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

control::reinstall() {
  HAS git || {
    ECHO2 Missing git
    exit
  }
  [[ -f .update-list ]] || {
    ECHO2 Missing '.update-list'.
    exit
  }

  assembly=$(grep 'VIM ASSEMBLY:' .update-list | cut -d ':' -f2)
  [[ $assembly =~ (extended|neovim-lua) ]] && _EXTEND=true

  local components
  utils::get_installed_components

  if [[ $1 = --no-reset ]]; then
    ECHO Reinstalling..

    ## Do not quote.
    control::install $components
    return
  fi

  msg+='By executing this command, all changes made to\n'
  msg+='the repository working tree will be lost. ABORT? [Y/n]\n'
  NOTE 210 "$msg"

  read -sn 1 -r
  ! [[ $REPLY = n ]] && {
    echo -e Aborted.
    exit
  }

  ECHO Reinstalling..

  git fetch -q || {
    echo Unable to fetch.
    exit 1
  }
  git reset --hard "origin/$(git rev-parse --abbrev-ref HEAD)"

  ## Do not quote.
  control::install $components
}
