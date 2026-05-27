#!/bin/zsh
set -e
## Available modes:
## - user (interactive installation)
## - auto (non-interactive, all packages)

ask_user() {
  local yes_or_no_question=$1 default_answer=${2:-y} prompt

  case $default_answer in
  y | Y) prompt='[Yn]'; REPLY=y ;;
  n | N) prompt='[yN]'; REPLY=n ;;
  *) print "Invalid default answer: $default_answer"; return 1 ;;
  esac

  if [[ $_MODE = user ]]; then
    read -k1 "REPLY?$yes_or_no_question $prompt "
    if [[ $REPLY =~ '[yYnN]' ]]; then
      print -u2
    elif [[ -z $REPLY ]]; then
      REPLY=$default_answer
      print -u2
    else
      print -u2 "
Invalid input: $REPLY
Please, type 'y' or 'n'"
      ask_user "$yes_or_no_question" "$default_answer"
    fi
  fi
}

select_packages() {
  local package default_answer
  local -a selected=()

  for package in "$@"; do
    [[ -n $package ]] || continue
    default_answer=y
    [[ $package = gitui ]] && default_answer=n
    ask_user "Install $package?" "$default_answer"
    [[ $REPLY =~ '[yY]' ]] && selected+=("$package")
  done

  printf '%s\n' $selected
}

select_default_packages() {
  local package
  local -a selected=()

  for package in "$@"; do
    [[ -n $package ]] || continue
    [[ $package = gitui ]] && continue
    selected+=("$package")
  done

  printf '%s\n' $selected
}

display_packages() {
  local package

  for package in "$@"; do
    if [[ $package = gitui ]]; then
      printf '  %s (default: no)\n' "$package"
    else
      printf '  %s\n' "$package"
    fi
  done
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
  local venv_dir="${XDG_DATA_HOME:-$HOME/.local/share}/evangelist/python"
  local bin_dir="$HOME/.local/bin"

  python3 -m venv "$venv_dir"
  "$venv_dir/bin/python" -m pip install -U pip
  "$venv_dir/bin/python" -m pip install -U -r pip.requirements.txt

  mkdir -p "$bin_dir"
  local tool
  for tool in ipython uv; do
    if [[ -x "$venv_dir/bin/$tool" ]]; then
      ln -sf "$venv_dir/bin/$tool" "$bin_dir/$tool"
    fi
  done

  print "Python dependencies installed in $venv_dir."
  print "Neovim Python host: $venv_dir/bin/python"
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

  print 'Homebrew is required to install system packages:'
  display_packages $brew_packages

  local -a selected_packages
  if [[ $_MODE = user ]]; then
    ask_user 'Install the default package set?'
    if [[ $REPLY =~ '[yY]' ]]; then
      selected_packages=("${(@f)$(select_default_packages $brew_packages)}")
    else
      ask_user 'Choose packages one by one?' n
      if [[ $REPLY =~ '[yY]' ]]; then
        selected_packages=("${(@f)$(select_packages $brew_packages)}")
      else
        selected_packages=()
      fi
    fi
  else
    print 'Installing default package set.'
    selected_packages=("${(@f)$(select_default_packages $brew_packages)}")
  fi

  if (( ${#selected_packages[@]} )); then
    _install_with_brew $selected_packages
  else
    print 'No Homebrew packages selected.'
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
