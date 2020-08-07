# XDG base directory setup
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export WGETRC="$XDG_CONFIG_HOME/wgetrc"

# ZSH
export ZDOTDIR="$HOME/.config/zsh"
export HISTFILE="$XDG_DATA_HOME/zsh_history"

# texlive
export PATH="$PATH:/usr/local/texlive/2020/bin/x86_64-linux"

# golang
export PATH="$PATH:/usr/local/go/bin"
export GOPATH="$HOME/Miscellanea/TestLab/go"
