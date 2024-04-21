#!/bin/bash
set -e

ask_user() {
  local yes_or_no_question=$1

  REPLY='y'
  if [[ $_MODE != as_root ]]; then
    read -rn1 -p "$yes_or_no_question [Yn] "
    [[ $REPLY =~ [yYnN] ]] || REPLY='y'
  fi
  echo
}

install() {
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
  apt_packages=$(awk '{$1=$1};1' <<<"$apt_packages")
  mapfile -t tmp_array < <(awk '{$1=$1};1' <<<"$apt_packages")
  apt_packages="${tmp_array[*]}"

  echo 'The root privileges are required to install the following packages:'
  echo "$apt_packages"

  ask_user 'Would you like to install them?'
  if [[ $REPLY =~ [yY] ]]; then
    $_sudo apt-get -qq update
    eval "$sudo_env $_sudo apt-get install -y $apt_packages"
  fi

  ask_user 'Install zsh (a more user friendly shell)?'
  if [[ $REPLY =~ [yY] ]]; then
    $_sudo apt-get -qq update ## In case, it wasn't updated previously
    eval "$sudo_env $_sudo apt-get install -y zsh"
  fi

  ask_user "Install Neovim's AppImage?"
  if [[ $_MODE != as_root && $REPLY =~ [yY] ]]; then
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    mkdir -p "$_HOME/.local/bin" && chmod +x nvim.appimage
    mv nvim.appimage "$_HOME/.local/bin"
    $_sudo ln -sf "$_HOME/.local/bin/nvim.appimage" /usr/bin/nvim
  fi

  if [[ $_MODE = as_root || $REPLY =~ [nN] ]]; then
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

  # ask_user "Install nerd fonts?"
  # if [[ $REPLY =~ [yY] ]]; then
  #   local default=FiraCode
  #   if [[ $_MODE != as_root ]]; then
  #     read -rp "Input fonts name [$default]:" FONTS
  #   fi
  #   wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/$FONTS.zip
  #   unzip $FONTS.zip -d ~/.fonts
  #   fc-cache -fv
  # fi

  ask_user 'Install Node.js?'
  if [[ $REPLY =~ [yY] ]]; then
    wget -O node-tmp.tar.gz -r -nd -A gz --accept-regex='node-.*-linux-x64\.tar\.gz' https://nodejs.org/download/release/latest/
    mkdir /tmp/node-tmp && tar xf node-tmp.tar.gz -C /tmp/node-tmp --strip-components=1
    mv /tmp/node-tmp/bin/node "$_HOME/.local/bin"

    # $_sudo apt-get -qq update ## In case, it wasn't updated previously
    # eval "$sudo_env $_sudo apt-get install -y ca-certificates curl gnupg"
    # $_sudo mkdir -p /etc/apt/keyrings
    # curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key |
    #   $_sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

    # local default=21
    # if [[ $_MODE != as_root ]]; then
    #   read -rp "Input node version [$default]:" NODE_MAJOR
    # fi
    # echo "NOTE this script may be too old to rely on its default major value"
    # echo "Check the latest version major on the internet"
    # echo "(Just in case, check the latest major version on the internet)"
    # local source=https://deb.nodesource.com/node_${NODE_MAJOR:-$default}.x
    # if ! grep -q "$source" /etc/apt/sources.list.d/nodesource.list; then
    #   echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] $source nodistro main" |
    #     sudo tee /etc/apt/sources.list.d/nodesource.list
    # fi
    # $_sudo apt-get -qq update ## required
    # $_sudo apt-get install -yq nodejs
  fi

  ask_user "Download ru-dictionary for Neovim's spellchecker?"
  if [[ $REPLY =~ [yY] ]]; then
    local folder="${XDG_DATA_HOME:-~/.local/share}/nvim/site/spell"
    curl -LO http://ftp.vim.org/vim/runtime/spell/ru.utf-8.spl &&
      mkdir -p $folder && mv ru.utf-8.spl $folder
  fi

  ask_user 'Set up gutui (fancy git add-ons: UI for git in CLI)?'
  if [[ $REPLY =~ [yY] ]]; then
    curl -LO https://github.com/extrawurst/gitui/releases/latest/download/gitui-linux-musl.tar.gz
    tar xf gitui-linux-musl.tar.gz -C "$_HOME/.local/bin/gitui"
    mkdir -p "$_HOME/.config/gitui"
    cp conf/git/key_bindings.ron "$_HOME/.config/gitui"
  fi

  ask_user 'Set up delta for prettier git diff?'
  if [[ $REPLY =~ [yY] ]]; then
    curl -LO https://github.com/dandavison/delta/releases/download/0.16.5/delta-0.16.5-x86_64-unknown-linux-musl.tar.gz
    cp delta-0.16.5-x86_64-unknown-linux-musl/delta "$_HOME/.local/bin"
    rm -rf delta-0.16.5-x86_64-unknown-linux-musl/delta
  fi

  ask_user 'Install Python dependencies?'
  if [[ $REPLY =~ [yY] ]]; then
    pip3 install $pip_opts -r pip.requirements.txt
  fi
}


install "$@"
