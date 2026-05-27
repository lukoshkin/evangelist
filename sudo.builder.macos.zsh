#!/bin/zsh
set -e
## Available modes:
## - user (interactive installation)
## - auto (non-interactive, all packages)

ask_user() {
  local yes_or_no_question=$1

  REPLY=y
  if [[ $_MODE = user ]]; then
    read -k1 "REPLY?$yes_or_no_question [Yn] "
    if [[ $REPLY =~ '[yYnN]' ]]; then
      print
    elif [[ -z $REPLY ]]; then
      REPLY=y
      print
    else
      print "
Invalid input: $REPLY
Please, type 'y' or 'n'"
      ask_user "$yes_or_no_question"
    fi
  fi
}

_require_macos() {
  if [[ $(uname) != Darwin ]]; then
    print 'sudo.builder.macos.zsh is intended for macOS only.'
    return 1
  fi
}

_activate_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  local brew_bin
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$brew_bin" ]]; then
      eval "$("$brew_bin" shellenv)"
      return
    fi
  done
}

_ensure_homebrew() {
  _activate_homebrew
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  print 'Homebrew is required to install macOS dependencies.'
  ask_user 'Install Homebrew?'
  if [[ $REPLY =~ '[yY]' ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    _activate_homebrew
    command -v brew >/dev/null 2>&1 || return 1
  else
    return 1
  fi
}

_install_xcode_cli_tools() {
  if xcode-select -p >/dev/null 2>&1; then
    return
  fi

  print 'Xcode Command Line Tools are required for compilers and headers.'
  ask_user 'Install Xcode Command Line Tools?'
  if [[ $REPLY =~ '[yY]' ]]; then
    xcode-select --install
    print 'Re-run this script after the Xcode Command Line Tools installer finishes.'
    exit 0
  fi
}

_install_with_brew() {
  brew update
  brew install "$@"
}

_install_cask_with_brew() {
  brew install --cask "$@"
}

_install_miniconda() {
  local arch installer tmp_dir

  case $(uname -m) in
  arm64)
    arch=MacOSX-arm64
    ;;
  x86_64)
    arch=MacOSX-x86_64
    ;;
  *)
    print "Unsupported macOS architecture: $(uname -m)"
    return 1
    ;;
  esac

  tmp_dir=/tmp/$(uuidgen)
  installer="$tmp_dir/miniconda.sh"
  mkdir -p "$tmp_dir"
  curl -fsSL "https://repo.anaconda.com/miniconda/Miniconda3-latest-$arch.sh" -o "$installer"
  bash "$installer" -ubp "$HOME/miniconda"
  "$HOME/miniconda/bin/conda" init "${SHELL:t}"
}

_install_python_deps() {
  python3 -m pip install -U -r pip.requirements.txt
}

install() {
  local _MODE=${1:-user}

  if [[ $_MODE != user && $_MODE != auto ]]; then
    print "Invalid mode: $_MODE
Valid modes are 'user', 'auto'"
    return 1
  fi

  _require_macos
  _install_xcode_cli_tools
  _ensure_homebrew

  local -a brew_packages=(
    automake
    bash
    cmake
    curl
    fd
    fzf
    gettext
    git
    git-delta
    gitui
    libtool
    luarocks
    neovim
    node
    openssl@3
    pkg-config
    python
    ripgrep
    ruby
    tmux
    tree
    wget
  )

  print 'The following Homebrew packages will be installed:'
  printf '  %s\n' $brew_packages

  ask_user 'Would you like to install them?'
  if [[ $REPLY =~ '[yY]' ]]; then
    _install_with_brew $brew_packages
  fi

  ask_user 'Install zsh?'
  if [[ $REPLY =~ '[yY]' ]]; then
    _install_with_brew zsh
  fi

  ask_user 'Install miniconda to create Python virtual envs?'
  if [[ $REPLY =~ '[yY]' ]]; then
    _install_miniconda
  fi

  ask_user 'Install Nerd fonts?'
  if [[ $REPLY =~ '[yY]' ]]; then
    _install_cask_with_brew font-fira-code-nerd-font
  fi

  ask_user "Install Neovim's extras?"
  if [[ $REPLY =~ '[yY]' ]]; then
    npm install -g neovim
    npm install -g tree-sitter-cli
    _install_python_deps
  fi

  ask_user "Download ru-dictionary for Neovim's spellchecker?"
  if [[ $REPLY =~ '[yY]' ]]; then
    local folder="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/spell"
    curl -LO http://ftp.vim.org/vim/runtime/spell/ru.utf-8.spl &&
      mkdir -p "$folder" && mv ru.utf-8.spl "$folder"
  fi

  ask_user 'Install Python dependencies?'
  if [[ $REPLY =~ '[yY]' ]]; then
    _install_python_deps
  fi

  ask_user 'Install latexmk to enable VimTex plugin?'
  if [[ $REPLY =~ '[yY]' ]]; then
    _install_with_brew latexmk
  fi
}

install "$@"
