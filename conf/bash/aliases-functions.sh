#!/bin/bash
## Not executable, the shebang is for syntax.
_shell=$(ps -p $$ -oargs=)
_shell=${_shell##*/}

## Setting search path for `cd` command properly.
if ! [[ $CDPATH =~ :?\.: ]]; then
  ## NOTE: quotes is not used with =~, otherwise,
  ## they are treated as a part of the pattern.
  [[ -z $CDPATH ]] && CDPATH=. || CDPATH=.:$CDPATH
fi

if ! [[ $CDPATH =~ ~ ]]; then
  CDPATH=$CDPATH:~
fi


## Alias completion in Zsh is possible after setting complete_aliases option
## or specifying `compdef alias_name=function_name`. I don't know how to
## complete aliases in Bash that are not connected to a function. Thus, at
## least `evangelist` should be a function. `evn` can be an alias to
## `evangelist` or its wrapper function.

evangelist () {
  "$EVANGELIST/evangelist.sh" "$@"
}

evn () {
  if [[ $# -gt 0 ]]; then
    evangelist "$@"
  elif [[ $PWD != "$EVANGELIST" ]]; then
    cd "$EVANGELIST" || return
  fi
}


alias l='ls -lAh'
alias ll='ls -lh'
alias lt='ls -lAht'

alias fd='find . -type d -name'
alias ff='find . -type f -name'
alias grep='grep --color'
alias rexgrep="grep -rIn --exclude-dir='.?*'"
alias o='xdg-open'

## Open the last file closed:
# alias v="vim +'e #<1'"
# alias v="vim +'execute \"normal \<C-P>\<Enter>\"'"
v () {
  if [[ $# -gt 0 ]]; then
    vim "$@"
    return
  fi

  if [[ -f "$XDG_CONFIG_HOME/init.vim" ]]; then
    vim +'execute "normal \<C-P>\<Enter>"'
  else
    vim +'normal \fo'
  fi
}

alias _vimrc="vim $XDG_CONFIG_HOME/nvim/init.*"
alias vimrc="vim $EVANGELIST/custom/custom.vim"

## Folder stack navigation.
alias d='dirs -v'
alias G='gg 0'

gg () {
  if [[ -z $1 ]]; then
    pushd +1 &> /dev/null
    [[ $? -ne 0 ]] && echo Singular dir stack || :

  elif [[ $1 = 0 ]]; then
    pushd -0 > /dev/null

  elif [[ $1 =~ ^[0-9]+$ ]]; then
    pushd +$1 > /dev/null

  elif [[ $1 =~ ^-[0-9]+$ ]]; then
    popd +${1:1}

  else
    echo Wrong args
  fi
}


tmp () {
  cd /tmp || return
  [[ -z $1 ]] && return
  eval "$*"
  cd - > /dev/null
}


tarz () {
  tar czf "$1.tar.gz" "$@"
}


_math () {
  ## _ANS can be reused later.
  _ANS=$(( $* ))
  echo $_ANS
}


st () {
  if [[ -n $1 ]] || ! git status 2> /dev/null; then
    eval "du -hm --max-depth=1 $1" | sort -n -r
  fi
}


if [[ $_shell = bash ]]; then
  ## Repeat the last command in Bash (just like in Zsh).
  r () {
    fc -s
  }

  ## Similar to Fish's `math`.
  alias math='_math'
else
  alias math='noglob _math'
fi


_mangle_name () {
  local name=$1
  no=$(sed -nr 's;.*\(([0-9]+)\)(\.[^\.]+)?$;\1;p' <<< "$name")

  if [[ -z $no ]]; then
    if [[ $name != *.* || -d /tmp/$name ]]; then
      name+='(1)'
    else
      name=$(sed -r 's;(.*)(\.[^\.]+);\1(1)\2;' <<< "$name")
    fi
  else
    copy_no=$(( no + 1 ))
    name=$(sed -r "s;(.*\()$no(\)(\.[^\.]+)?)\$;\1$copy_no\2;" <<< "$name")
  fi

  echo "$name"
}


mv () {
  ## Something like 'gvfs-trash' implementation.
  ## When passing just one argument, it "removes" file or folder
  ## backing it up at the "trash bin" (/tmp).

  ## Some of concerns:
  ## - /tmp is a limited in size partition
  ## - `while`-loop
  command -v realpath &> /dev/null
  local code=$?

  if [[ $# != 1 || $code -ne 0 ]]; then
    command mv "$@"
  else
    local no copy_no parent
    local loop_cnt=0 max_loop_cnt=100
    local name=$1 landing=/tmp
    parent=$(realpath "$(dirname "$name")")

    if [[ $parent = "/tmp" ]]; then
      echo "You can't use one-arg mv cmds in /tmp dir."
      return 1
    fi

    while [[ -e /tmp/$name ]]; do
      name=$(_mangle_name "$name")

      (( loop_cnt ++ ))
      if [[ $loop_cnt -ge $max_loop_cnt ]]; then
        echo "EVANGELIST's Impl.error: infinite loop"
        return 1
      fi
    done

    [[ $name != "$1" ]] && landing+="/$name"

    command mv "$1" "$landing" \
      && echo "$1 has been moved to $landing."
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

  ## 124 - command timed out
  if [[ $? -eq 124 ]]; then
    echo 'Try to run it in one of subfolders.'
    return
  fi

  # ls -R | grep ":$" | sed -e 's/:$//' \
  find . -not -path '*/.*' -type d -print | sed -e \
    's;[^-][^\/]*\/;--;g' -e 's;^;   ;' -e 's;-;|;'
}


tree () {
  if ! command -v tree &> /dev/null
  then
    dtree "$1"
    return
  fi

  local w8
  local hierarchy

  [[ -n $1 ]] && w8=$1 || w8=.1
  ## 'script' preserves output colors (one of its assets)
  ## Since script saves the output to a file, /dev/null is used to discard it

  ## -e - return exit code of the child process
  ## -q - don't write start-end timestamps
  ## -c - command to execute
  hierarchy=$(script -eqc "timeout --preserve-status $w8 tree" /dev/null)

  ## 143 - SIGTERM (process was killed by another one)
  if [[ $? -eq 143 ]]; then
    echo 'Try to run it in one of subfolders.'
    return
  fi

  ## double quotes are required in bash
  echo "$hierarchy"
}


swap () {
  [[ -z $1 || -z $2 ]] && { echo 'Requires src and dest'; return 1; }
  local bak="/tmp/${1##*/}.bak"

  cp -R "$1" "$bak" \
    && rm -rf "$1" \
    && mv "$2" "$1" \
    && mv "$bak" "$2"
}


bak () {
  for file in "$@"; do
    [[ -e bak.$file ]] && { echo "bak.$file already exists"; return 1; }
    cp -r "$file" "bak.$file"
  done
}


_think_before () {
  local nsec=$1
  while [[ $(( nsec -= 1 )) -gt 0 ]]; do
    echo "You have $nsec second(s) to change your mind"
    sleep 1
  done
}


rm () {
  if [[ " $* " =~ ' -rf ' ]]; then
    _think_before 5
  fi
  command rm -I "$@"
}


vrmswp () {
  [[ -z $1 ]] && { echo "Pass the name of swap file to delete."; return 1; }
  local swp=${1//\//%}
  rm "$XDG_DATA_HOME/nvim/swap/"*$swp*
}


## https://stackoverflow.com/questions/1527049
join_by () {
  local d=$1 f=$2
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}


(which tmux &> /dev/null \
  && grep -qE '^n?vim' "$EVANGELIST/.update-list" \
  && grep -q '^source .*slime\.vim' "$XDG_CONFIG_HOME/nvim/init.vim" \
  && grep -q '^source .*ipython\.vim' "$XDG_CONFIG_HOME/nvim/init.vim") \
  &> /dev/null && source "$EVANGELIST/conf/tmux/templates.sh"

## Save to use from the interactive shell?
# unset _shell
