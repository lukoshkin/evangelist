#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
WHITE=$(tput setaf 15)

# NOTE: bold text modifier (below) doesn't affect
# ####  colors defined as the first three above
BOLD=$(tput bold)
RESET=$(tput sgr0)


ECHO () {
  local RAIN=$(tput setaf 152)
  local PURPLE=$(tput setaf 111)
  echo -e "${BOLD}${PURPLE}EVANGELIST ~>$RESET ${RAIN}$@${RESET}"
}

NOTE () {
  local COLOR=$(tput setaf $1)
  echo -e "\n${BOLD}${COLOR}$2${RESET}"
}

ECHO2 () {
  local SALMON=$(tput setaf 210)
  local BUFF=$(tput setaf 186)
  >&2 echo -e "${BOLD}${SALMON}EVANGELIST:${RED}PROBLEM:$RESET ${BUFF}$@${RESET}"
}


instructions_after_install () {
  locale -a | grep -qiE '^[a-z]{2}_?[a-z]*\.utf8$'
  local CODE=$?

  NOTE 210 "\nFURTHER INSTRUCTIONS:"
  printf 'TO FINISH THE INSTALLATION, '
  if [[ ${SHELL##*/} != $1 ]]
  then
    printf "CHANGE THE CURRENT SHELL TO $(tr a-z A-Z <<< $1),\n\n"
    printf "\t${BOLD}${WHITE}chsh -s $(which $1)$RESET\n\n"
  fi
  if [[ $CODE -eq 1 ]]
  then
    printf "GENERATE 'en_US' LOCALES,\n"
    printf '(You can choose another one)\n\n'
    printf "\t${BOLD}${WHITE}sudo locale-gen en_US.UTF-8$RESET\n\n"
  fi
  printf 'LOG OUT FROM THE CURRENT ACCOUNT. '
  printf 'THEN, LOG IN BACK.\n'
}

instructions_after_removal () {
  NOTE 210 "\nFURTHER INSTRUCTIONS:"
  printf 'TO FINISH THE REMOVAL, '
  if [[ -n $1 && ${SHELL##*/} != $1 ]]
  then
    printf 'RESTORE THE ORIGINAL VALUE OF THE LOGIN SHELL.'
    printf "\n\n\t${BOLD}${WHITE}chsh -s $(which $1)$RESET\n\n"
  fi
  printf 'CLOSE YOUR CURRENT SHELL AND OPEN A NEW ONE.\n'
}


prepend_text () {
  if [[ $(uname) == Darwin ]]
  then
    sed -i '' "1i\\
$2\\
" $1
  else
    [[ -z $2 ]] && { sed -i '1i\\' $1; return; }
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

  prepend_text $1 ''
  prepend_text $1 "export XDG_CACHE_HOME=\"$XDG_CACHE_HOME\""
  prepend_text $1 "export XDG_DATA_HOME=\"$XDG_DATA_HOME\""
  prepend_text $1 "export XDG_CONFIG_HOME=\"$XDG_CONFIG_HOME\""
  prepend_text $1 '# XDG bash directory specification'

  if [[ $1 =~ bash ]]
  then
    prepend_text $1 ''
    prepend_text $1 '[ -z "$PS1" ] && return'
    prepend_text $1 '# If not running interactively, do not do anything.'
  fi
}


add_entry_to_update_list () {
  grep -q "^$1" update-list.txt \
    || echo $1 >> update-list.txt
}


# NOTE: stderr-pipe redirection (|&) doesn't work on old shells
HAS () {
  [[ $(type $@ 2>&1 | grep -c 'not found') -lt $# ]] && return 0
  return 1
}

modulecheck () {
  echo -e "${BOLD}\n$1$RESET"
  local delim=$(printf "%${#1}s")
  echo -e "${BOLD}${delim// /-}$RESET"

  shift

  local required=()
  local optional=()

  while [[ -n $1 ]]
  do
    local m=$(cut -d ':' -f1 <<< $1)
    local v=$(cut -d ':' -f2 <<< $1)
    local n=$(cut -d ':' -f3 <<< $1)

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
      echo -e "${GREEN}All dependencies are satisfied!$RESET"
      ;;
    1)
      echo -e "${YELLOW}Some of features may not work.$RESET"
      local COLOR=$YELLOW
      ;;
    *)
      echo -e "${RED}Cannot be installed.$RESET"
      local COLOR=$RED
      ;;
  esac

  [[ $ok -gt 0 ]] && echo -e "${COLOR}Missing the following packages:\n$RESET"
  [[ ${#required[@]} -ne 0 ]] && echo -e "${RED}[required]$RESET"

  for p in ${required[@]}
  do
    echo -e "  $p"
  done

  [[ ${#optional[@]} -ne 0 ]] && echo -e "${YELLOW}[optional]$RESET"

  for p in ${optional[@]}
  do
    echo -e "  $p"
  done
  echo
}


str_has_any () {
  local intersection=0
  local stringset=$1

  while [[ -n $2 ]]
  do
    [[ $stringset =~ $2 ]] && (( intersection+=1))
    shift
  done

  [[ $intersection -gt 0 ]] && return 0
  return 1
}


_help () {
  echo -e "Usage: ./evangelist.sh [cmd] [args]\n"
  echo -e "Commands:\n"

  printf "  %-20s Update the repository and installed configs.\n" 'update'
  printf "  %-20s Install one of the specified setups: bash zsh notebook.\n" 'install'
  printf "  %-20s Show the installation status or readiness to install.\n" 'checkhealth'
  printf "  %-20s Roll back to the original settings.\n" 'uninstall'
  printf "  %-20s Show this message and quit.\n" 'help'
}
