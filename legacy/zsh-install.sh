# XDG specification
[[ -z $XDG_CONFIG_HOME ]] && export XDG_CONFIG_HOME="$HOME/.config"
[[ -z $XDG_DATA_HOME ]] && export XDG_DATA_HOME="$HOME/.local/share"
[[ -z $XDG_CACHE_HOME ]] && export XDG_CACHE_HOME="$HOME/.cache"

# ZPLUG env vars
[[ -z $ZDOTDIR ]] && export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
[[ -z $ZPLUG_HOME ]] && export ZPLUG_HOME="$XDG_DATA_HOME/zplug"

mkdir -p $XDG_CONFIG_HOME
mkdir -p $XDG_DATA_HOME
mkdir -p $XDG_CACHE_HOME
mkdir -p $ZDOTDIR
mkdir -p $ZPLUG_HOME

# Copy configs
cp zsh/zshrc $ZDOTDIR/.zshrc
cp zsh/{agkozakrc,extra.zsh,conda_autoenv.sh} $ZDOTDIR
cp zsh/zshenv ~/.zshenv

which tmux \
  && cp tmux.conf ~/.tmux.conf \
  || (mkdir -p $XDG_CACHE_HOME/tmux; \
    cp tmux.conf $XDG_CACHE_HOME/tmux/tmux.conf)

cp -r nvim $XDG_CONFIG_HOME

# Install zsh and all necessities
sudo apt-get -qq update
sudo apt-get install -yq \
  git neovim tmux curl npm x11-apps locales zsh

#sudo mkdir -p /usr/local/lib/node_modules
#sudo chown -R $USER /usr/local/lib/node_modules
npm install -g neovim
which pip3 && pip3 install --upgrade pynvim


# Change shell to zsh
chsh -s $(which zsh)


# Install zplug
git clone https://github.com/zplug/zplug $ZPLUG_HOME


# Install vim-plug
vimPlug="$XDG_DATA_HOME/nvim/site/autoload/plug.vim"
[[ ! -f $vimPlug ]] \
  && sh -c "curl -fLo $vimPlug --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

# Install vim-plugins
nvim +source $XDG_CONFIG_HOME/nvim/init.vim +q
nvim +PlugInstall +qall


# Set anacron job
which anacron && sudo cp anacron/anacrontab.young /etc/anacrontab


# Add conda init to zshrc
[[ -n $CONDA_EXE ]] && $CONDA_EXE init zsh || :
