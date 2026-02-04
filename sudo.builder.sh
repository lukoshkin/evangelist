#!/bin/bash
set -e
## Available modes:
## - user (interactive installation)
## - docker (non-interactive, not all packages, implies root privileges)
## - auto (non-interactive, all packages)

_get_latest_tag() {
  local repo=$1
  curl --silent "https://api.github.com/repos/$repo/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"tag_name": *"([^"]+)".*/\1/'
}

_extract_exe_to_bin() {
  local tar_archive=$1
  local executable=$2
  local tmp_dir=/tmp/$(uuidgen)

  mkdir -p "$tmp_dir"
  mv "$tar_archive" "$tmp_dir"
  tar -xf "$tmp_dir/$tar_archive" -C "$tmp_dir" --strip-components=1 &&
    cp "$tmp_dir/$executable" "$_HOME/.local/bin"
}

_install_with_apt() {
  $_sudo apt-get -qq update
  eval "$sudo_env $_sudo apt-get install -y $*"
}

ask_user() {
  local yes_or_no_question=$1

  REPLY='y'
  if [[ $_MODE = user ]]; then
    read -rn1 -p "$yes_or_no_question [Yn] "
    if [[ $REPLY =~ [yYnN] ]]; then
      echo
    elif [[ -z $REPLY ]]; then
      REPLY='y'
      echo
    else
      echo -e "\nInvalid input: $REPLY\nPlease, type 'y' or 'n'"
      ask_user "$yes_or_no_question"
    fi
  fi
}

install() {
  local sudo_env _sudo=sudo pip_opts=-U
  local _MODE=${1:-user} _HOME=${2:-~}

  ## Check mode is valid
  if [[ $_MODE != user && $_MODE != docker && $_MODE != auto ]]; then
    echo -e "Invalid mode: $_MODE\nValid modes are 'user', 'docker', 'auto'"
    return 1
  fi

  if [[ $_MODE != user ]]; then
    pip_opts=--no-cache-dir
    sudo_env=DEBIAN_FRONTEND=noninteractive
  fi

  if [[ $_MODE = docker ]]; then
    _sudo=
  fi

  local apt_packages
  apt_packages=$(sed -e 's;\(.*\)\(#.*\);\1;' apt.requirements.txt)
  # read -ra apt_packages -d '\n' <<< "$apt_packages"
  ## Returns exit status 1

  declare -a tmp_array
  apt_packages=$(awk '{$1=$1};1' <<<"$apt_packages")
  mapfile -t tmp_array < <(awk '{$1=$1};1' <<<"$apt_packages")
  apt_packages="${tmp_array[*]}"

  echo 'The root privileges are required to install the following packages:'
  echo "$apt_packages"

  ask_user 'Would you like to install them?'
  if [[ $REPLY =~ [yY] ]]; then
    _install_with_apt "$apt_packages"
  fi

  ask_user 'Install zsh (a more user friendly shell)?'
  if [[ $REPLY =~ [yY] ]]; then
    _install_with_apt zsh
  fi

  ask_user 'Install miniconda to create Python virtual envs?'
  if [[ $_MODE != docker && $REPLY =~ [yY] ]]; then
    curl -o miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash miniconda.sh -ubp "$HOME/miniconda"
    ## -b = batch mode (non-interactive),
    ## -u = update (ignore if installed already)
    ## -p <PREFIX> = installation prefix
    "$HOME/miniconda/bin/conda" init ${SHELL##*/}
    exec ${SHELL##*/}
  fi

  ask_user "Install Neovim's AppImage?"
  if [[ $_MODE != docker && $REPLY =~ [yY] ]]; then
    local link=https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
    local dl_path="$_HOME/.local/bin"

    mkdir -p "$dl_path"
    curl -L $link -o "$dl_path/nvim"
    chmod +x "$dl_path/nvim"
    ## No longer needed as we have ~/.local/bin on PATH
    # $_sudo ln -sf "$dl_path/nvim" /usr/bin/nvim
  fi

  if [[ $_MODE = docker || $REPLY =~ [nN] ]]; then
    ask_user 'Install Neovim from source?'
    if [[ $REPLY =~ [yY] ]]; then
      ## NOTE: `pkg-config automake libtool-bin gettext`
      ## might be removed after the installation.
      git clone https://github.com/neovim/neovim &&
        cd neovim && git checkout stable &&
        make CMAKE_BUILD_TYPE=Release &&
        make install &&
        cd .. && rm -rf neovim
    fi
  fi

  ask_user 'Install Nerd fonts?'
  if [[ $_MODE != docker && $REPLY =~ [yY] ]]; then
    local default=FiraCode
    if [[ $_MODE != docker ]]; then
      read -rp "Input fonts name [$default]:" FONTS
    fi
    local tag
    tag=$(_get_latest_tag ryanoasis/nerd-fonts)
    echo "Downloading ${FONTS:=$default} fonts.."
    wget -nc "https://github.com/ryanoasis/nerd-fonts/releases/download/$tag/${FONTS:=$default}.zip"
    unzip "$FONTS.zip" -d ~/.fonts
    # fc-cache -fv  # not sure it is helpful
  fi

  ask_user 'Install Node.js and npm?'
  if [[ $REPLY =~ [yY] ]]; then
    local tmp_dir
    tmp_dir=/tmp/$(uuidgen)
    mkdir -p "$tmp_dir" && cd "$tmp_dir" &&
      wget -r -nd -A gz --accept-regex='node-.*-linux-x64\.tar\.gz' \
        https://nodejs.org/download/release/latest/ &&
      tar xf node* --strip-components=1 &&
      mkdir -p "$_HOME/.local" &&
      cp -r bin lib share "$_HOME/.local/" &&

      # Configure npm to use local directories (no sudo needed)
      mkdir -p "$_HOME/.local/share/npm-global" &&
      "$_HOME/.local/bin/npm" config set prefix "$_HOME/.local/share/npm-global"

    if [[ ":$PATH:" == *":$_HOME/.local/bin:"* ]] &&
      [[ ":$PATH:" == *":$_HOME/.local/share/npm-global/bin:"* ]]; then
      echo "Node.js and npm installed locally. PATH already configured."
    fi

    local shell_config=""
    case "${SHELL##*/}" in
    zsh)
      shell_config="${ZDOTDIR:-$_HOME}/.zshrc"
      ;;
    bash)
      shell_config="$_HOME/.bashrc"
      [[ ! -f "$shell_config" && -f "$_HOME/.bash_profile" ]] && {
        shell_config="$_HOME/.bash_profile"
      }
      ;;
    *)
      >&2 echo "Unsupported shell: $SHELL."
      echo -n "Please, add \$HOME/.local/bin and"
      echo " \$HOME/.local/share/npm-global/bin to your PATH manually."
      return 1
      ;;
    esac

    local new_path_dirs="\$HOME/.local/bin:\$HOME/.local/share/npm-global/bin"
    if grep -q "^\\(export \\)\\?PATH=" "$shell_config"; then
      sed -i.bak "s|^\\(export \\)\\?PATH=|\\1PATH=\"$new_path_dirs:\"|" "$shell_config"
      echo "Updated PATH in $shell_config"
    else
      {
        echo ""
        echo "# Added by evangelist installer"
        echo "export PATH=\"$new_path_dirs:\$PATH\""
      } >>"$shell_config"
      echo "Added PATH export to $shell_config"
    fi
    echo "Node.js and npm installed locally. Restart your shell"
  fi

  ask_user "Install Neovim's extras?"
  if [[ $_MODE = user && $REPLY =~ [yY] ]]; then
    [[ -z $(command -v npm) ]] && {
      echo 'npm is not installed! Skipping..'
    } || {
      npm install -g neovim
      npm install -g tree-sitter-cli
      pip3 install $pip_opts neovim
    }
    ## Go
    # local latest
    # latest=$(
    #   curl -s "https://go.dev/dl/?mode=json" |
    #   grep -Po '"filename":\s*"\Kgo[0-9.]+linux-amd64.tar.gz' |
    #   head -1
    # )
    # wget -nc https://go.dev/dl/$latest &&
    #   rm -rf "$HOME/.local/bin/go" &&
    #   tar -C "$HOME/.local/bin" -xzf go1.23.2.linux-amd64.tar.gz
  fi

  ask_user "Download ru-dictionary for Neovim's spellchecker?"
  if [[ $_MODE != docker && $REPLY =~ [yY] ]]; then
    local folder="${XDG_DATA_HOME:-~/.local/share}/nvim/site/spell"
    curl -LO http://ftp.vim.org/vim/runtime/spell/ru.utf-8.spl &&
      mkdir -p "$folder" && mv ru.utf-8.spl "$folder"
  fi

  ask_user 'Set up gutui (fancy git add-ons: UI for git in CLI)?'
  if [[ $_MODE != docker && $REPLY =~ [yY] ]]; then
    local tag
    tag=$(_get_latest_tag extrawurst/gitui)
    echo TAG $tag
    curl -LO "https://github.com/extrawurst/gitui/releases/download/$tag/gitui-linux-x86_64.tar.gz" &&
      _extract_exe_to_bin "gitui-linux-x86_64.tar.gz" gitui &&
      mkdir -p "$_HOME/.config/gitui" &&
      cp conf/git/key_bindings.ron "$_HOME/.config/gitui"
  fi

  ask_user 'Set up delta for prettier git diff? (works only after `evn install git`)'
  if [[ $_MODE != docker && $REPLY =~ [yY] ]]; then
    local tag delta repo=dandavison/delta
    tag=$(_get_latest_tag $repo)
    delta=delta-$tag-x86_64-unknown-linux-musl
    curl -LO "https://github.com/$repo/releases/download/$tag/$delta.tar.gz" &&
      _extract_exe_to_bin "$delta.tar.gz" delta
  fi

  ask_user 'Install Python dependencies?'
  if [[ $REPLY =~ [yY] ]]; then
    pip3 install $pip_opts -r pip.requirements.txt
  fi

  ask_user 'Install SafeEyes? To make some interval eye gymnastics'
  if [[ $_MODE != docker && $REPLY =~ [yY] ]]; then
    $_sudo add-apt-repository -y ppa:safeeyes-team/safeeyes
    $_sudo apt-get update && eval $sudo_env $_sudo apt-get install -y safeeyes
  fi

  ask_user 'Install latexmk to enable VimTex plugin?'
  if [[ $_MODE = user && $REPLY =~ [yY] ]]; then
    eval $sudo_env $_sudo apt-get install -y latexmk
  fi
}

install "$@"
