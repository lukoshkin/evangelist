#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
PINK='\e[38;5;219m'

BOLD='\033[1m'
NOFONT='\033[0m'


ECHO () {
  echo -e "${BOLD}${PINK}EVANGELIST =>$NOFONT $@"
}

ECHO2 () {
  >&2 echo -e "${BOLD}${PINK}EVANGELIST:${RED}PROBLEM:$NOFONT $@"
}


print_further_instructions () {
  [[ ${SHELL##*/} == $1 ]] && return 

  ECHO "FURTHER INSTRUCTIONS:"
  printf "TO FINISH THE INSTALLATION "
  printf "RUN THE FOLLOWING COMMAND \n"
  printf "(It changes the current shell to $1)\n\n"
  printf "\tchsh -s $(which $1)\n\n"
  printf "AND LOG OUT FROM THE CURRENT ACCOUNT. "
  printf "THEN, LOG IN BACK.\n"
}


prepend_text () {
  if [[ $(uname) == Darwin ]]
  then
    sed -i '' "1s/^/$2\'$'\n/" $1
  else
    sed -i "1i $2" $1
  fi
}

make_descriptor () {
  if [[ $1 =~ zsh ]]
  then
    prepend_text $1 'export ZPLUG_CACHE_DIR="$XDG_CACHE_HOME/zplug"'
    prepend_text $1 "export ZPLUG_HOME=\"$ZPLUG_HOME\""
    prepend_text $1 "export ZDOTDIR=\"$ZDOTDIR\""
    prepend_text $1 '# ZSH'
  fi

  prepend_text $1 "export XDG_CACHE_HOME=\"$XDG_CACHE_HOME\""
  prepend_text $1 "export XDG_DATA_HOME=\"$XDG_DATA_HOME\""
  prepend_text $1 "export XDG_CONFIG_HOME=\"$XDG_CONFIG_HOME\""
  prepend_text $1 '# XDG bash directory specification'

  if [[ $1 =~ bash ]]
  then
    prepend_text $1 '[ -z "$PS1" ] && return'
    prepend_text $1 '# If not running interactively, do not do anything.'
  fi
}


HAS () {
  [[ $(type $@ |& grep -c 'not found') -lt $# ]] && return 0
  return 1
}

modulecheck () {
  echo -e "${BOLD}\n$1$NOFONT"
  delim=$(printf "%${#1}s"); echo -e "${BOLD}${delim// /-}$NOFONT"

  shift

  required=()
  optional=()

  while [[ -n $1 ]]
  do
    local m=$(cut -d ':' -f 1 <<< $1)
    local v=$(cut -d ':' -f 2 <<< $1)
    local n=$(cut -d ':' -f 3 <<< $1)

    if [[ $m == r ]]
    then
      HAS $v || { [[ -z $n ]] && required+=($v) || required+=($n); }
    elif [[ $m == o ]]
    then
      HAS $v || { [[ -z $n ]] && optional+=($v) || optional+=($n); }
    else
      echo Wrong argument specification
      exit 1
    fi
    shift
  done

  local ok=0
  [[ ${#required[@]} -ne 0 ]] && (( ok+=2 ))
  [[ ${#optional[@]} -ne 0 ]] && (( ok+=1 ))

  case $ok in 
    0)
      echo -e "${GREEN}All dependencies are satisfied!$NOFONT"
      ;;
    1)
      echo -e "${ORANGE}Some of features may not work.$NOFONT"
      local COLOR=$ORANGE
      ;;
    *)
      echo -e "${RED}Cannot be installed.$NOFONT"
      local COLOR=$RED
      ;;
  esac

  [[ $ok -gt 0 ]] && echo -e "${COLOR}Missing the following packages:\n$NOFONT"
  [[ ${#required[@]} -ne 0 ]] && echo -e "${RED}[required]$NOFONT"

  for p in ${required[@]}
  do
    echo -e "  $p"
  done

  [[ ${#optional[@]} -ne 0 ]] && echo -e "${ORANGE}[optional]$NOFONT"

  for p in ${optional[@]}
  do
    echo -e "  $p"
  done
  echo
}
