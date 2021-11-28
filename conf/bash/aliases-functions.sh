## Setting search path for `cd` command properly.
if ! [[ $CDPATH =~ ':?\.:' ]]
then
  [[ -z $CDPATH ]] && CDPATH=. || CDPATH=.:$CDPATH
fi

if ! [[ $CDPATH =~ ~ ]]
then
  CDPATH=$CDPATH:~
fi


## With `setopt complete_aliases` in zsh, both `evn` and `evangelist`
## aliases can be completed with Tab. However, it is hardly possible
## to complete aliases not connected to any function in bash. Therefore,
## we define `evangelist` as a function and `evn` as an alias to it.
## (in zsh this is also valid after adding `compdef evn=evangelist`).
evangelist () {
  "$EVANGELIST"/evangelist.sh $@
}

alias evn=evangelist

alias l='ls -lAh'
alias ll='ls -lh'
alias lt='ls -lAht'

alias fd='find . -type d -name'
alias ff='find . -type f -name'
alias grep='grep --color'
alias rexgrep="grep -r --exclude-dir='.?*'"

## Open the last file closed:
# alias v="vim +'e #<1'"
alias v="vim +'execute \"normal \<C-P>\<Enter>\"'"
type nvim &> /dev/null \
  && alias vv="vim +'browse filter !/__\|NERD_tree\|ControlP/ oldfiles'"

alias _vimrc="vim $XDG_CONFIG_HOME/nvim/init.vim"
alias vimrc="vim $EVANGELIST/custom/custom.vim"

## Folder stack navigation.
alias d='dirs -v'
alias G='gg 0'

gg () {
  if [[ -z $1 ]]
  then
    pushd +1 &> /dev/null
    [[ $? -ne 0 ]] && echo Singular dir stack || :
  elif [[ $1 == 0 ]]
  then
    pushd -0 > /dev/null
  elif [[ $1 =~ ^[0-9]+$ ]]
  then
    pushd +$1 > /dev/null
  elif [[ $1 =~ ^-[0-9]+$ ]]
  then
    popd +${1:1}
  else
    echo Wrong args
  fi
}


## Some other functions that might be useful.
md () {
  mkdir -p "$@"
  [[ $# -gt 1 ]] && return 1
  cd "$1"
}


dtree () {
  local w8
  [[ -n $1 ]] && w8=$1 || w8=.5

  timeout $w8 find . ! -path '*/\.*' -type d &> /dev/null

  # 124 - command timed out
  if [[ $? -eq 124 ]]
  then
    echo 'Try to run it in one of subfolders.'
    return
  fi

  ls -R | grep ":$" | sed -e 's/:$//' \
    -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/'
}


tree () {
  if command -v tree &> /dev/null
  then
    dtree $1
    return
  fi

  local w8
  local hierarchy

  [[ -n $1 ]] && w8=$1 || w8=.1
  # 'script' preserves output colors (one of its assets)
  #  Since script saves the output to a file, /dev/null is used to discard it

  # -e - return exit code of the child process
  # -q - don't write start-end timestamps
  # -c - command to execute
  hierarchy=$(script -eqc "timeout --preserve-status $w8 tree" /dev/null)

  # 143 - SIGTERM (process was killed by another one)
  if [[ $? -eq 143 ]]
  then
    echo 'Try to run it in one of subfolders.'
    return
  fi

  # double quotes are required in bash
  echo "$hierarchy"
}


swap () {
  [[ -z $1 || -z $2 ]] && { echo 'Requires src and dest'; return 1; }

  cp -R $1 /tmp/$1.bak \
    && rm -rf $1 \
    && mv $2 $1 \
    && mv /tmp/$1.bak $2
}


(grep -qE '^n?vim' "$EVANGELIST"/.update-list \
  && grep -q '^Plug .*vim-slime' "$XDG_CONFIG_HOME"/nvim/init.vim) \
  && source "$EVANGELIST"/conf/tmux/templates.sh

