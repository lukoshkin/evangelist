# ALIASES
# -------
alias -g ...=../..
alias -g ....=../../..
alias -g .....=../../../..
alias -g ......=../../../../..

alias l='ls -lAh'
alias ll='ls -lAht'
alias ls='ls --color=tty'
alias md='mkdir -p'

alias fd='find . -type d -name'
alias ff='find . -type f -name'
alias grep='grep --color'

function tree() {
  #########################
  # Draws the project tree.
  #########################
  local w8
  local threshold
  local treesize

  [[ -n $1 ]] && threshold=$1 || threshold=100
  [[ -n $2 ]] && w8=$2 || w8=1 

  treesize=$(wc -l < <(timeout $w8 \
    find . -not -path '*/\.*' -type d 2> /dev/null))

  if [[ $treesize -gt $threshold ]]
  then
    echo "The project tree is too large!"
    echo "There are $treesize directories found in less than $w8 second(s)."
    printf "Try to run the command in a subfolder "
    printf "or relax the project traversing conditions.\n"
  else
      ls -R | grep ":$" | sed -e 's/:$//' \
        -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/'
  fi
}

alias zshrc="vim $ZDOTDIR/.zshrc"
alias vimrc="vim ~/.config/nvim/init.vim"
## To list all active aliases, run `alias`

function tor() {
  local tordir="$HOME/BuildPacks/Tor/tor-browser_en-US"
  cd $tordir && ./start-tor-browser.desktop && cd > /dev/null
}



# CONSOLE INPUT
# -------------
## Key repeat rate (to navigate faster with a key pressed)
xset r rate 250 70

## Some cozy bindings
### First line says: use vim bindings map
bindkey -v
bindkey -M viins 'jj' vi-cmd-mode
bindkey -M viins '^Q' push-line
bindkey -M viins '^U' backward-delete-char
bindkey -M viins '^P' delete-char
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down
bindkey -M vicmd '/' history-interactive-fuzzy-search

## Requires installed fuzzy finder (fzf)
function history-interactive-fuzzy-search() {
  local _buffer=$BUFFER
  BUFFER=$(cat $XDG_DATA_HOME/zsh_history | fzf)
  [[ -z $BUFFER ]] && BUFFER=$_buffer
}

## 'zle -N <widget_name>' creates a user-defined widget, or overwrites
## active one with the same name as specified in the option.
zle -N history-interactive-fuzzy-search

## Meta(=Alt) + j/k to match the beginning of a command history
### -------- block begins --------
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

function from-ins-beginning-search-up() {
  zle vi-cmd-mode
  zle up-line-or-beginning-search
}

function from-ins-beginning-search-down() {
  zle vi-cmd-mode
  zle down-line-or-beginning-search
}

zle -N from-ins-beginning-search-up
zle -N from-ins-beginning-search-down

bindkey -M viins '^[k' from-ins-beginning-search-up
bindkey -M viins '^[j' from-ins-beginning-search-down
bindkey -M vicmd '^[k' up-line-or-beginning-search
bindkey -M vicmd '^[j' down-line-or-beginning-search
### -------- block ends --------

bindkey '^[[Z' reverse-menu-complete
bindkey '^[w' forward-word  # complete word in a suggestion
## * To list zsh bindings, execute 'bindkey' without arguments
## * To find some laptop (Ubuntu) bindings that contain <pattern>,
##   use 'gsettings list-recursively | grep <pattern>'.

ZLS_COLORS="no=00:fi=00:di=01;34:ln=01;36:\ 
  pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:\ 
  or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:\ 
  *.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:\ 
  *.z=01;31:*.Z=01;31:*.gz=01;31:*.deb=01;31:\ 
  *.jpg=01;35:*.gif=01;35:*.bmp=01;35:*.ppm=01;35:\ 
  *.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:\ 
  *.mpg=01;37:*.avi=01;37:*.gl=01;37:*.dl=01;37:"

## Sets for the completion menu "similar to ls command" colors.
zstyle ':completion:*' list-colors ${(s.:.)ZLS_COLORS}
## 'ignorecase'+'smartcase'+'hyphen_insensitive' completion on the cmd line.
zstyle ':completion:*' matcher-list 'm:{[:lower:]-_}={[:upper:]_-}'
##  Highlight for the selected completion menu item.
zstyle ':completion:*' menu select search

## Except default completion (_complete), it enables alias expantion with 
## TAB (_expand_alias), use of glob (_match) and ignored-patterns (_ignored).
zstyle ':completion:*' completer _complete _expand_alias _match #_ignored
# zstyle ':completion:*' ignored-patterns '<pattern-to-be-ignored>'


# STYLE CONTROL
# -------------
## The following settings allow to change the terminal window transparency
## from the command line (not from an editor or another app opened in the console).
## Requires 'transset' to be installed. One can change the transparency
## in the range [0, max], where 'max' is the transparency value defined
## in preferences of the terminal. And consistently with the last statement,
## the value by which transparency is changed with functions below is relative,
## not absolute.
function incr-transp() {
  transset -a --inc .02 > /dev/null
}

function decr-transp() {
  transset -a --dec .02 > /dev/null
}

zle -N incr-transp
zle -N decr-transp

## <Alt - '+' > = decrease transparency a bit
## <Alt - '-' > = increase transparency a bit
bindkey -M vicmd '^[+' incr-transp
bindkey -M vicmd '^[-' decr-transp

## Set on startup transparency
transset -a .9 > /dev/null



# CLEAN HISTORY LOOKUP
# --------------
## Exporting ignorecommon as HISTORY_IGNORE ruins everything (why?)
ignorecommon="(\
^cd ?$|\
^l[las]? ?$|\
^vi[m]? ?$|\
^echo ?$|\
^pwd ?$|\
^clear ?$|\
^man \S*$|\
^tmux ?$|\
^dirs -v$|\
^pushd ?$|^pushd [+-][0-9]*$|\
^popd ?$|^popd [+-][0-9]*$"

ignorecommon+="|\
^vi[m]? [^/]*$|\
^l[las]? \S+$|\
^cd [^/]*$|\
^mkdir .*$|\
^echo \S+$)"

## Zsh hook on appending lines to the history file. Note:
## a command is added to history before being executed.
zshaddhistory() {
  emulate -L zsh
  ! [[ $(tr -s ' ' <<< ${1%%$'\n'}) =~ $ignorecommon ]];
}



# ZSH OPTIONS
#------------
## zsh options are case insensitive and ignore underscores in the name.
setopt autopushd
setopt pushdignoredups
## Option prefixed with 'no' is the inversion of the original.
## Same effect can be achieved with 'unsetopt' keyword.
setopt nobeep

setopt histignorealldups
setopt histreduceblanks

setopt extendedglob
## quite powerful option which enables:
## - recursive globbing     ls **/foo       foo, dir1/foo, dir1/dir2/foo
## - negation               ls ^foo         all except foo
## - approximate matching   ls (#a1)foobar  fobar, 
## - qualifiers             ls foo/*(#q@)   finds all symblic links (@) in foo 
## more info by googling article: 37-ZSH-Gem-2-Extended-globbing-and-expansion.html



# AUTO CONDA ENV
[[ -n $CONDA_EXE ]] && source $ZDOTDIR/conda_autoenv.sh
