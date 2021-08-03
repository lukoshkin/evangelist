#!/bin/bash

RED='\033[0;31m'
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
WHITE=$(tput setaf 15)

# NOTE: tput bold text modifier doesn't affect
# ####  colors defined not with tput
BOLD=$(tput bold)
RESET=$(tput sgr0)


########################
# -----> MACROS -----> #
########################

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

# NOTE: stderr-pipe redirection (|&) doesn't work on old shells
HAS () {
  [[ $(type $@ 2>&1 | grep -c 'not found') -lt $# ]] && return 0
  return 1
}

########################
# <----- MACROS <----- #
########################


# Takes one argument - shell rc-file where to append imports
write::dynamic_imports () {
  grep -q '# Dynamic (on-install) imports' $1 \
    || echo -e '\n# Dynamic (on-install) imports' >> $1

  [[ $1 =~ bash ]] && ! grep -q 'source .*/conf/bash/ps1.bash' $1 \
    && echo 'source "$EVANGELIST/conf/bash/ps1.bash"' >> $1

  conda &> /dev/null || return

  local line GITIGNORE
  line=$(git config -l | grep 'core.excludesfile')

  if [[ -n $line ]]
  then
    GITIGNORE=$(cut -d '=' -f2 <<< $line)
  else
    GITIGNORE="$XDG_CONFIG_HOME/git/ignore"
    mkdir -p "${GITIGNORE%/*}" && touch "$GITIGNORE"
    git config --global core.excludesfile "$GITIGNORE"
  fi

  grep '.autoenv.evn' "$GITIGNORE" &> /dev/null \
    || echo '.autoenv.evn.*' >> "$GITIGNORE"
  grep -q 'source "$EVANGELIST/conf/zsh/conda-autoenv.sh"' $1 \
    || echo 'source "$EVANGELIST/conf/zsh/conda-autoenv.sh"' >> $1
}

# Takes one argument - shell for which to install settings: bash or zsh
write::instructions_after_install () {
  locale -a | grep -qiE '^[a-z]{2}_?[a-z]*\.utf8$'
  local CODE=$?

  NOTE 210 '\nFURTHER INSTRUCTIONS:'
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

  if [[ ${SHELL##*/} != $1 ]]
  then
    printf 'LOG OUT FROM THE CURRENT ACCOUNT. THEN, LOG IN BACK.\n'
  else
    printf 'KILL THE CURRENT SHELL AND START A NEW INSTANCE.'
    printf "\n\n\t${BOLD}${WHITE}exec $1${RESET}\n\n"
  fi
}

# Takes one argument - the shell that was before
# the settings installation: bash or zsh
write::instructions_after_removal () {
  NOTE 210 '\nFURTHER INSTRUCTIONS:'
  printf 'TO FINISH THE REMOVAL, '
  if [[ -n $1 && ${SHELL##*/} != $1 ]]
  then
    printf 'RESTORE THE ORIGINAL VALUE OF THE LOGIN SHELL.'
    printf "\n\n\t${BOLD}${WHITE}chsh -s $(which $1)${RESET}\n\n"
    printf 'LOG OUT FROM THE CURRENT ACCOUNT. THEN, LOG IN BACK.\n'
  else
    printf 'KILL THE CURRENT SHELL AND START A NEW INSTANCE.'
    printf "\n\n\t${BOLD}${WHITE}exec $1${RESET}\n\n"
  fi
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

# Takes one argument - shell for which to install settings: bash or zsh
write::file_header () {
  if [[ $1 =~ zsh ]]
  then
    prepend_text $1 ''
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

  prepend_text $1 ''
  prepend_text $1 "export EVANGELIST=\"$PWD\""

  if [[ $1 =~ bash ]]
  then
    prepend_text $1 ''
    prepend_text $1 '[ -z "$PS1" ] && return'
    prepend_text $1 '# If not running interactively, do not do anything.'
  fi
}


write::modulecheck () {
  echo -e "${BOLD}${WHITE}\n$1$RESET"
  local delim=$(printf "%${#1}s")
  echo -e "${BOLD}${delim// /-}$RESET"

  shift

  local required=()
  local optional=()

  local m v n
  while [[ -n $1 ]]
  do
    m=$(cut -d ':' -f1 <<< $1)
    v=$(cut -d ':' -f2 <<< $1)
    n=$(cut -d ':' -f3 <<< $1)

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


write::commit_messages () {
  # 1 commit -> full message
  # more than 1 -> only title

  local nrows format branch=$1
  nrows=$(git rev-list HEAD..origin/$branch | wc -l)
  [[ $nrows == 1 ]] && format=%B || format=%s
  git log HEAD..origin/$branch --format=$format
}

