#!/bin/bash

## in `docker build` command `TERM=dumb` is used
if [[ $TERM = dumb ]]; then
  tput () {
    :
  }
fi

RED='\033[0;31m'
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
WHITE=$(tput setaf 15)
BLUE=$(tput setaf 33)
GRAY=$(tput setaf 246)

## NOTE: tput bold text modifier doesn't affect
## ####  colors defined not with tput.
BOLD=$(tput bold)
RESET=$(tput sgr0)


##########################
## -----> MACROS -----> ##
##########################

ECHO () {
  local RAIN=$(tput setaf 152)
  local PURPLE=$(tput setaf 111)
  echo -e "${BOLD}${PURPLE}EVANGELIST ~>$RESET ${RAIN}$@${RESET}"
}


NOTE () {
  local color=$(tput setaf $1)
  echo -e "\n${BOLD}${color}$2${RESET}"
}


ECHO2 () {
  local SALMON=$(tput setaf 210)
  local BUFF=$(tput setaf 186)
  >&2 echo -e "${BOLD}${SALMON}EVANGELIST:${RED}PROBLEM:$RESET ${BUFF}$@${RESET}"
}


## NOTE: stderr-pipe redirection (|&) doesn't work on old shells
HAS () {
  [[ $(type $@ 2>&1 | grep -c 'not found') -lt $# ]] && return 0
  return 1
}


HASLIB () {
  dpkg-query -W $1 &> /dev/null
}

##########################
## <----- MACROS <----- ##
##########################


## Takes one argument - shell rc-file where to append imports
write::dynamic_imports () {
  grep -q '## Dynamic (on-install) imports' $1 \
    || echo -e '\n## Dynamic (on-install) imports' >> $1

  [[ $1 =~ bash ]] && ! grep -q 'source .*/conf/bash/ps1.bash' $1 \
    && echo 'source "$EVANGELIST/conf/bash/ps1.bash"' >> $1

  if conda &> /dev/null
  then
    local line GITIGNORE
    line=$(git config -l | grep 'core.excludesfile')

    if [[ -n $line ]]; then
      GITIGNORE=$(cut -d '=' -f2 <<< $line)
    else
      GITIGNORE="$XDG_CONFIG_HOME/git/ignore"
      mkdir -p "${GITIGNORE%/*}" && touch "$GITIGNORE"
      git config --global core.excludesfile "$GITIGNORE"
    fi

    grep '.autoenv-evn' "$GITIGNORE" &> /dev/null \
      || echo '.autoenv-evn.*' >> "$GITIGNORE"
    grep -q 'source "$EVANGELIST/conf/zsh/conda-autoenv.sh"' $1 \
      || echo 'source "$EVANGELIST/conf/zsh/conda-autoenv.sh"' >> $1
  fi

  if ! grep -q 'source "$EVANGELIST/custom/custom\..*sh"' $1
  then
    if [[ $1 =~ zsh ]]; then
      echo '[[ -f "$EVANGELIST/custom/custom.zsh" ]] \' >> $1
      echo '  && source "$EVANGELIST/custom/custom.zsh"' >> $1
      echo -e '\nzcomet compinit' >> $1

    elif [[ $1 =~ bash ]]; then
      echo '[[ -f "$EVANGELIST/custom/custom.bash" ]] \' >> $1
      echo '  && source "$EVANGELIST/custom/custom.bash" || :' >> $1
    fi
  fi
}


## Takes one argument - shell for which to install settings: bash or zsh
write::instructions_after_install () {
  if [[ -n $_MSG ]] || [[ -n $_PARAMS ]]; then
    NOTE 210 '\nFURTHER INSTRUCTIONS:'
    printf 'TO FINISH THE INSTALLATION, '
  fi

  if [[ -n $_MSG ]]; then
    printf "SET VIM'S ALTERNATIVE TO USE, e.g.,\n"
    printf '(One can google other ways to do it w/o sudo)\n\n'
    printf "\t${BOLD}${WHITE}$_MSG${RESET}\n\n"
    printf "Or simply: \t${BOLD}${WHITE}exec ${SHELL##*/}${RESET},\n"
    printf 'since currently, there are aliases like vim=nvim defined.\n\n'
  fi

  if [[ -n $_PARAMS ]]; then
    if [[ -n $1 ]]; then
      locale -a | grep -qiE '^[a-z]{2}_?[a-z]*\.utf8$'
      local code=$?

      if [[ ${SHELL##*/} != $1 ]]; then
        printf "CHANGE THE CURRENT SHELL TO $(tr a-z A-Z <<< $1),\n\n"
        printf "\t${BOLD}${WHITE}chsh -s $(which $1)${RESET}\n\n"
      fi

      if [[ $code -eq 1 ]]; then
        printf "GENERATE AND UPDATE LOCALES\n"
        printf "(You can choose other than 'en_US'),\n\n"
        printf "\t${BOLD}${WHITE}sudo locale-gen en_US.UTF-8$RESET\n"
        printf "\t${BOLD}${WHITE}sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8$RESET\n\n"
      fi
    fi

    ## When to echo `exec *sh`? Almost in any case where re-login
    ## is not a necessity. This is because Vim settings based on some
    ## environment variables, and some aliases related to Vim are being
    ## sourced on the shell startup. Tmux and Jupyter settings might
    ## require in future re-launching the shell due the same reasons.
    ## Another approach is to "parse" _PARAMS, and print instructions
    ## for each case. It is better in terms of functionality, but not
    ## if we consider "functionality - implementation efforts" trade-off.
    if [[ -n $1 ]] && [[ ${SHELL##*/} != $1 ]]; then
      printf 'LOG OUT FROM THE CURRENT ACCOUNT. THEN, LOG IN BACK.\n'
    else
      printf 'KILL THE CURRENT SHELL AND START A NEW INSTANCE.'
      printf "\n\n\t${BOLD}${WHITE}exec ${SHELL##*/}$RESET\n\n"
    fi
  fi
}


## Operates on '.update-list' file
write::instructions_after_removal () {
  local shell curr orig msg
  shell=$(grep 'LOGIN-SHELL' .update-list | cut -d ':' -f2)

  NOTE 210 '\nFURTHER INSTRUCTIONS:'
  printf 'TO FINISH THE REMOVAL, '
  ## `-n` is an unnecessary test under the current implementation. We always
  ## add info about the login shell on the creation of '.update-list'. Unlike
  ## Vim's alternative, a line about it is only added if `update-alternatives`
  ## is available on the OS. Still, it is good to have this extra sanity
  ## check here.

  if [[ -n $shell ]] && [[ ${SHELL##*/} != $shell ]]; then
    printf 'RESTORE THE ORIGINAL VALUE OF THE LOGIN SHELL.'
    printf "\n\n\t${BOLD}${WHITE}chsh -s $(which $shell)${RESET}\n\n"
    printf 'LOG OUT FROM THE CURRENT ACCOUNT. THEN, LOG IN BACK.\n'
  else
    curr=$(update-alternatives --query vim | grep 'Value:' | cut -d ' ' -f2)
    orig=$(grep 'VIM-ALTERNATIVE' .update-list 2> /dev/null | cut -d: -f2)

    if [[ -n $orig ]] && [[ $curr != $orig ]]; then
      msg="${BOLD}${WHITE}sudo update-alternatives --set vim ${orig}${RESET}"
      printf 'RESTORE THE ORIGINAL VALUE OF THE VIM ALTERNATIVE.'
      printf "\n\n\t$msg\n\n"
    fi

    ## The following instruction is only needed
    ## when environment variables should be updated;
    ## but just in case, it is printed every time.
    printf 'KILL THE CURRENT SHELL AND START A NEW INSTANCE.'
    printf "\n\n\t${BOLD}${WHITE}exec ${shell}${RESET}\n\n"
  fi
}


_prepend_text () {
  if [[ $(uname) = Darwin ]]; then
    sed -i '' "1i\\
$2\\
" $1
  else
    [[ -z $2 ]] && { sed -i '1i\\' $1; return; }
    sed -i "1i $2" $1
  fi
}


## Takes one argument - shell for which to install settings: bash or zsh
write::file_header () {
  if [[ $1 =~ zsh ]]; then
    _prepend_text $1 ''
    _prepend_text $1 "export ZDOTDIR=\"$ZDOTDIR\""
    _prepend_text $1 '## ZSH'
  fi

  _prepend_text $1 ''
  _prepend_text $1 "export XDG_CACHE_HOME=\"$XDG_CACHE_HOME\""
  _prepend_text $1 "export XDG_DATA_HOME=\"$XDG_DATA_HOME\""
  _prepend_text $1 "export XDG_CONFIG_HOME=\"$XDG_CONFIG_HOME\""
  _prepend_text $1 '## XDG bash directory specification'

  _prepend_text $1 ''
  _prepend_text $1 "export EVANGELIST=\"$PWD\""

  if [[ $1 =~ bash ]]; then
    _prepend_text $1 ''
    _prepend_text $1 '[ -z "$PS1" ] && return'
    _prepend_text $1 '## If not running interactively, do not do anything.'
  fi
}


_register_package () {
  local out
  local newer=false
  local v1 v2=$1

  ## It is not necessary to check these two conditions since
  ## `utils::v1_ge_v2` handles these cases (empty variables, to be exact).
  ## However, it slightly reduces exec. time and prevents error messages.
  if [[ -n $v2 ]] && HAS $package
  then
    v1=$(dpkg-query -W -f '${Version}\n' $package 2> /dev/null)
    [[ -z $v1 ]] && v1=$(eval "$package --version 2> /dev/null")
    ## NOTE: `grep -E` doesn't work with non-capturing groups.
    v1=$(grep -oE '[0-9]+(\.[0-9]+)+' <<< $v1)
    utils::v1_ge_v2 $v1 $v2 && newer=true
  else
    newer=true
  fi

  case $mode in
    [ro+]l) has () { HASLIB $1; } ;;
    *) has () { HAS $@; } ;;
  esac

  if ! has $package || ! $newer
  then
    [[ -n $v2 ]] && v2="${GRAY}>=${v2}$RESET"
    ## NOTE: There should be no spaces in `out`, and thus, `v2`,
    ## since the former is an element of an array with default IFS.
    [[ -z $name ]] && out=(${package}$v2) || out=(${name}$v2)
  fi

  echo $out
}


_diagnostics () {
  local title=$1
  local color=$2
  shift 2

  [[ $# -ne 0 ]] && echo -e "$color[$title]$RESET"

  for p in $@; do
    echo -e "  $p"
  done
}


write::modulecheck () {
  echo -e "${BOLD}${WHITE}\n$1${RESET}"
  local delim=$(printf "%${#1}s")
  echo -e "${BOLD}${delim// /-}${RESET}"

  shift

  local required=()
  local optional=()
  local extended=()
  local mode name package version

  while [[ -n $1 ]]; do
    mode=$(cut -d ':' -f1 <<< $1)
    name=$(cut -d ':' -f3 <<< $1)
    package=$(cut -d ':' -f2 <<< $1)
    version=$(cut -d ':' -f4 <<< $1)

    case $mode in
      r*) required+=($(_register_package $version)) ;;
      o*) optional+=($(_register_package $version)) ;;
      +*) extended+=($(_register_package $version)) ;;
      *) echo Wrong argument specification; exit 1 ;;
    esac

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
      local color=$YELLOW
      ;;
    *)
      echo -e "${RED}Cannot be installed.$RESET"
      local color=$RED
      ;;
  esac

  [[ $ok -gt 0 ]] && echo -e "${color}Missing the following packages:$RESET"

  echo
  _diagnostics required $RED ${required[@]}
  _diagnostics optional $YELLOW ${optional[@]}
  _diagnostics 'for extensions' $BLUE ${extended[@]}
  echo
}


write::how_to_install_conda () {
  link=https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

  if [[ $(uname) != Linux ]]; then
    link='https://repo.anaconda.com/miniconda/<find-propper-link>'
  fi

  echo -e '\nTo install conda, you can copy-paste the following snippet:'

  cmd=( "\n\n\tcurl -o miniconda.sh $link\n" )
  cmd+=( '\tbash miniconda.sh -b -p "$HOME/miniconda"\n' )
  cmd+=( '\t"$HOME/miniconda/bin/conda" init'" ${SHELL##*/}\n" )
  cmd+=( "\texec ${SHELL##*/}\n\n" )
  echo -e ${BOLD}${WHITE}${cmd[@]}${RESET}

  echo If one has wget installed instead of curl or prefer
  printf "using one over the other, substitute ${BOLD}${WHITE}curl -o$RESET"
  printf " with ${BOLD}${WHITE}wget -O$RESET\n"
  echo leaving the remaining code unchanged.
}


write::commit_messages () {
  ## 1 commit -> full message
  ## more than 1 -> only title

  local nrows format branch=$1
  nrows=$(git rev-list HEAD..origin/$branch | wc -l)
  [[ $nrows = 1 ]] && format=%B || format=%s
  git log HEAD..origin/$branch --format=$format
}

