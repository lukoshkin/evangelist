## ZSH ALIASES
## -----------
alias -g ...=../..
alias -g ....=../../..
alias -g .....=../../../..
alias -g ......=../../../../..
alias ls='ls --color=tty'

alias _zshrc="vim $ZDOTDIR/.zshrc"
alias zshrc="vim $EVANGELIST/custom/custom.zsh"
## To list all active aliases, run `alias`


## CONSOLE INPUT
## -------------
## Key repeat rate (to navigate faster with a key pressed)
xset r rate 250 70 2> /dev/null

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
  type fzf &> /dev/null || return
  local _buffer=$BUFFER
  BUFFER=$(cat "$XDG_DATA_HOME/zsh_history" | fzf)
  [[ -z $BUFFER ]] && BUFFER=$_buffer
}

zle -N history-interactive-fuzzy-search


## Meta(=Alt) + j/k to match the beginning of a command history
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

function insert-space-cmd-mode() {
  zle magic-space
  zle vi-cmd-mode
  zle vi-forward-char
}

zle -N insert-space-cmd-mode

bindkey -M viins '^[k' insert-space-cmd-mode
bindkey -M viins '^[j' insert-space-cmd-mode
bindkey -M vicmd '^[k' up-line-or-beginning-search
bindkey -M vicmd '^[j' down-line-or-beginning-search

bindkey '^[[Z' reverse-menu-complete
bindkey '^[w' forward-word  # complete word in a suggestion
## * To list zsh bindings, execute 'bindkey' without arguments
## * To find some laptop (Ubuntu) bindings that contain <pattern>,
##   use 'gsettings list-recursively | grep <pattern>'.

## Delete the first 'word' in a command and go into insert mode.
function change-prefix {
  # local all_but_f1=$(cut -d' ' -f2- <<< "$BUFFER")
  # BUFFER=" $all_but_f1"
  zle beginning-of-line
  zle delete-word
  zle vi-insert
}

zle -N change-prefix

bindkey -M viins '^a' change-prefix
bindkey -M vicmd '^a' change-prefix


## Export standard ls colors (grep selects everything between '')
type dircolors &> /dev/null && eval "$(dircolors -b)"
## Sets for the completion menu "similar to ls command" colors.
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
## 'ignorecase'+'smartcase'+'hyphen_insensitive' completion on the cmd line.
zstyle ':completion:*' matcher-list 'm:{[:lower:]-_}={[:upper:]_-}'
##  Highlight for the selected completion menu item.
zstyle ':completion:*' menu select

zmodload zsh/complist
## Without loading 'zsh/complist', menuselect is not available.
bindkey -M menuselect '?' history-incremental-search-forward

## In addition to context-sensitive completion (_complete), it also enables
## alias expansion with TAB (_expand_alias), use of glob (_match),
## ignored-patterns (_ignored), and checking whether the word is eligible for
## expansion (_expand - unused). The order: '_expand', then '_complete', then
## '_match' ─ is according to ZSH guide
zstyle ':completion:*' completer _expand_alias _complete _match #_ignored
# zstyle ':completion:*' ignored-patterns '<pattern-to-ignore>'


## STYLE CONTROL
## -------------
## The following settings allow to change the terminal window transparency
## from the command line (not from an editor or another app opened in the console).
## Requires 'transset' to be installed. One can change the transparency
## in the range [0, max], where 'max' is the transparency value defined
## in preferences of the terminal. And consistently with the last statement,
## the value by which transparency is changed with functions below is relative,
## not absolute.
function incr-transp() {
  type transset &> /dev/null || return
  transset -a --inc .02 > /dev/null
}

function decr-transp() {
  type transset &> /dev/null || return
  transset -a --dec .02 > /dev/null
}

zle -N incr-transp
zle -N decr-transp

## <Alt - '+' > = decrease transparency a bit
## <Alt - '-' > = increase transparency a bit
bindkey -M vicmd '^[+' incr-transp
bindkey -M viins '^[+' incr-transp
bindkey -M vicmd '^[-' decr-transp
bindkey -M viins '^[-' decr-transp


## ZSH OPTIONS
## -----------
## Zsh options are case insensitive and ignore underscores in the name.
setopt autopushd
setopt pushdignoredups
## Option prefixed with 'no' is the inversion of the original.
## Same effect can be achieved with 'unsetopt' keyword.
setopt nobeep
setopt noflow_control
## The last one is for unbinding flow control keys: C-s and C-q

setopt extendedglob
## quite powerful option which enables:
## - recursive globbing     ls **/foo       foo, dir1/foo, dir1/dir2/foo
## - negation               ls ^foo         all except foo
## - approximate matching   ls (#a1)foobar  fobar,
## - qualifiers             ls foo/*(#q@)   finds all symblic links (@) in foo
## more info by googling article: 37-ZSH-Gem-2-Extended-globbing-and-expansion.html

## ZSH HISTORY
## -----------
## Append entries to $HISTFILE immediately if running ssh.
[[ -n $SSH_CLIENT ]] || [[ -n $SSH_TTY ]] && setopt sharehistory
## Don't append the following patterns to the $history array.
ignore_list=('.{1,3}' 'gg [0-9-]+' echo clear tmux )
HIST_SCRAPER_IGNORE="(^$(join_by '$|^' ${ignore_list[@]})$)"
## Remove these patterns from $HISTFILE on shell logout.
HISTORY_IGNORE="(mv *|mkdir *|man *|math *|type *|which *|whence *)"
unset ignore_list

## EVANGELIST COMPLETIONS (ZSH)
## ----------------------------
fpath+=( "$EVANGELIST/completions" )
compdef evn=evangelist
