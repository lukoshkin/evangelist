# ZSH ALIASES
# -------
alias -g ...=../..
alias -g ....=../../..
alias -g .....=../../../..
alias -g ......=../../../../..
alias ls='ls -G'

alias _zshrc="vim $ZDOTDIR/.zshrc"
alias zshrc="vim $XDG_CONFIG_HOME/evangelist/custom/custom.zsh"
## To list all active aliases, run `alias`



# CONSOLE INPUT
# -------------
## Some cozy bindings
### First line says: use vim bindings map
bindkey -v
bindkey -M viins 'jj' vi-cmd-mode
bindkey -M viins '^?' backward-delete-char
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down
bindkey -M vicmd '/' history-interactive-fuzzy-search
bindkey -M viins '^Q' push-input
bindkey -M vicmd '^Q' push-input-from-cmd

## 'zle -N <widget_name>' creates a user-defined widget, or overwrites
## active one with the same name as specified in the option.
zle -N push-input-from-cmd
function push-input-from-cmd() {
  zle push-input
  zle vi-insert
}

## Requires installed fuzzy finder (fzf)
function history-interactive-fuzzy-search() {
  local _buffer=$BUFFER
  BUFFER=$(cat $XDG_DATA_HOME/zsh_history | fzf)
  [[ -z $BUFFER ]] && BUFFER=$_buffer
}

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

# Colors for ls command
export LSCOLORS=Exfxcxdxbxegedabagacad
## Export standard ls colors (grep selects everything between '')
LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:';
export LS_COLORS

## Sets for the completion menu "similar to ls command" colors.
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
## 'ignorecase'+'smartcase'+'hyphen_insensitive' completion on the cmd line.
zstyle ':completion:*' matcher-list 'm:{[:lower:]-_}={[:upper:]_-}'
##  Highlight for the selected completion menu item.
zstyle ':completion:*' menu select search

## Except context-sensitive completion (_complete), it enables alias expansion
## with TAB (_expand_alias), use of glob (_match), ignored-patterns (_ignored),
## and checking whether the word is eligible for expansion (_expand - unused).
## order: '_expand', then '_complete', then '_match' - according to ZSH guide
zstyle ':completion:*' completer _expand_alias _complete _match #_ignored
# zstyle ':completion:*' ignored-patterns '<pattern-to-ignore>'



# CLEAN HISTORY LOOKUP
# --------------------
## Not able to set up the functionality of this section with HISTORY_IGNORE
## Exporting HISTORY_IGNORE ruins everything (why?)

_ignorecommon="(\
^v ?$|\
^d ?$|\
^gg ?[0-9-]*$|\
^G ?$|\
^cd ?$|\
^l[las]? ?$|\
^vi[m]? ?$|\
^echo ?$|\
^pwd ?$|\
^clear ?$|\
^man \S*$|\
^tmux ?$"

_ignorecommon+="|\
^vi[m]? ~?\/?[^/-]*$|\
^l[las]? \S+$|\
^cd \/?[^/]*$|\
^mkdir .*|\
^mv .*|\
^type .*|\
^which .*|\
^whence .*|\
^echo \S+$)"

## Zsh hook on appending lines to the history file. Note:
## a command is added to history before being executed.
zshaddhistory() {
  emulate -L zsh
  ! [[ $(tr -s ' ' <<< ${1%%$'\n'}) =~ $_ignorecommon ]];
}



# ZSH OPTIONS
#------------
## zsh options are case insensitive and ignore underscores in the name.
setopt autopushd
setopt pushdignoredups
## Option prefixed with 'no' is the inversion of the original.
## Same effect can be achieved with 'unsetopt' keyword.
setopt nobeep
setopt noflow_control
## The last one is for unbinding flow control keys: C-s and C-q

setopt hist_ignore_space
setopt histignorealldups
setopt histreduceblanks

setopt extendedglob
## quite powerful option which enables:
## - recursive globbing     ls **/foo       foo, dir1/foo, dir1/dir2/foo
## - negation               ls ^foo         all except foo
## - approximate matching   ls (#a1)foobar  fobar, 
## - qualifiers             ls foo/*(#q@)   finds all symblic links (@) in foo 
## more info by googling article: 37-ZSH-Gem-2-Extended-globbing-and-expansion.html
