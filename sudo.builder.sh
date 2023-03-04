#!/bin/bash
set -e

ask_user () {
  local yes_or_no_question=$1

  REPLY='y'
  if [[ $_MODE != as_root ]]; then
    read -rn1 -p "$yes_or_no_question [Yn] "
    [[ -z $REPLY ]] && REPLY='y'
  fi
  echo
}

install () {
  local sudo_env _sudo=sudo pip_opts=-U
  local _MODE=$1 _HOME=${2:-~}

  if [[ $_MODE = as_root ]]; then
    pip_opts=--no-cache-dir
    sudo_env=DEBIAN_FRONTEND=noninteractive
    _sudo=
  fi

  local apt_packages
  apt_packages=$(sed -e 's;\(.*\)\(#.*\);\1;' apt.requirements.txt)
  # read -ra apt_packages -d '\n' <<< "$apt_packages"
  ## Returns exit status 1

  declare -a tmp_array
  apt_packages=$(awk '{$1=$1};1' <<< "$apt_packages")
  mapfile -t < <(awk '{$1=$1};1' <<< "$apt_packages") tmp_array
  apt_packages="${tmp_array[*]}"

  echo 'The root privileges are required to install the following packages:'
  echo "$apt_packages"

  ask_user 'Would you like to install them?'
  if [[ $REPLY =~ [yY] ]]; then
    $_sudo apt-get -qq update
    eval "$sudo_env $_sudo apt-get install -y $apt_packages"
  fi

  ask_user "Install Neovim's AppImage?"
  if [[ $_MODE != as_root && $REPLY =~ [yY] ]]; then
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    mkdir -p "$_HOME/.local/bin" && chmod +x nvim.appimage
    mv nvim.appimage "$_HOME/.local/bin"
    $_sudo ln -s "$_HOME/.local/bin/nvim.appimage" /usr/bin/nvim
  fi

  if [[ $_MODE = as_root || $REPLY =~ [nN] ]]; then
    ask_user 'Install Neovim from source?'
    if [[ $REPLY =~ [yY] ]]; then
      ## NOTE: `pkg-config automake libtool-bin gettext`
      ## might be removed after the installation.
      git clone https://github.com/neovim/neovim \
        && cd neovim && git checkout stable \
        && make CMAKE_BUILD_TYPE=Release \
        && make install \
        && cd .. && rm -rf neovim
    fi
  fi

  ask_user 'Install the latest Node.js version?'
  if [[ $REPLY =~ [yY] ]]; then
    curl -fsSL https://deb.nodesource.com/setup_current.x | $_sudo bash -
    $_sudo apt-get install -yq nodejs
  fi

  ask_user 'Install Python dependencies?'
  if [[ $REPLY =~ [yY] ]]; then
    pip3 install $pip_opts -r pip.requirements.txt
  fi
}


install "$@"
