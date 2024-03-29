#!/bin/bash
## Shebang helps the editor to correctly render colors.


## This function should be called only once
## within the body of an install::*_settings function

## NOTE: another option is to implement it as follows:
## - in install.sh units, there might be several function calls
## - there is also a mandatory call to it w/o args in control.sh

## That is,
## in install.sh: back_up_original_configs f:file d:dir
## in control.sh: back_up_original_configs

## Check out the commented code section below.
utils::back_up_original_configs () {
  if ! grep -q "^$1" .update-list
  then
    ## A bit outdated code section, but can be still valid.
    ## Needs to be checked.
    # echo $1 >> /tmp/update-evn-list

    # if [[ -z $1 ]]
    # then
    #   cat /tmp/update-evn-list >> .update-list
    #   rm -f /tmp/update-evn-list
    # fi

    echo "$1:0" >> .update-list
    shift

    local arg m v n
    ## `arg` is made local, because it previously overwrote
    ## the value of the outer `arg` used in `control::install`.
    ## Though, the outer was renamed to `_ARG` (it is used within
    ## `install::vim_settings` now), it is better to separate
    ## eponymous variables with `local` specifier.
    for arg in "$@"; do
      m=$(cut -d ':' -f1 <<< "$arg")
      v=$(cut -d ':' -f2 <<< "$arg")
      n=$(cut -d ':' -f3 <<< "$arg")

      v=$(eval echo "$v")
      n=$(eval echo "$n")
      case $m in
        f)
          [[ -f "$v" ]] && cp "$v" ".bak/$n"
          ;;
        d)
          [[ -d "$v" ]] && cp -R "$v" ".bak/$n"
          ;;
        *)
          echo Wrong argument
          exit 1
          ;;
      esac
    done
  fi
}


utils::update_status () {
  for p in "${_PARAMS[@]}"; do
    sed -i "s;\(^$p:\)[01];\11;" .update-list
  done
}


utils::get_installed_components () {
  components=$(sed '1,/Installed/d' .update-list 2> /dev/null)
  ## sed: comma specifies the operating range, where endpoints are included
  ## and can be patterns. If called without args, sed prints the current
  ## buffer. One can use $ as the EOF marker.

  components=$(sed -n 's;\(.*\):1;\1;p' <<< "$components" | tr '\n' ' ')
  ## Space separated clean component names from `.update-list`.
}


utils::str_has_any () {
  local intersection=0
  local stringset=$1

  while [[ -n $2 ]]; do
    [[ $stringset =~ $2 ]] && (( intersection+=1 ))
    shift
  done

  [[ $intersection -gt 0 ]] && return 0
  return 1
}


utils::v1_ge_v2 () {
  [[ -z $1 || -z $2 ]] && return 1
  [[ ${1//v} = "${2//v}" ]] && return 0

  ## Check if there is more than one hyphen.

  local sep=$3
  [[ -z $sep ]] && sep=.
  local verstr1=$1 verstr2=$2

  local suf1 suf2
  verstr1=$(cut -d- -f1 <<< "$1")
  suf1=$(cut -d- -f2 <<< "$1")

  verstr2=$(cut -d- -f1 <<< "$2")
  suf2=$(cut -d- -f2 <<< "$2")

  [[ $suf1 = "$verstr1" ]] && suf1=
  [[ $suf2 = "$verstr2" ]] && suf2=

  if [[ -z $suf1 ]] && [[ -z $suf2 ]]; then
    :
  elif [[ -z $suf1 ]]; then
    suf1="${suf2}a"
  elif [[ -z $suf2 ]]; then
    suf2="${suf1}a"
  fi

  local shear
  declare -a version1 version2
  if [[ $(readlink /proc/$$/exe) = *bash ]]; then
    IFS=$sep read -ra version1 <<< "${verstr1//v}"
    IFS=$sep read -ra version2 <<< "${verstr2//v}"
    shear=0
  elif [[ $(readlink /proc/$$/exe) = *zsh ]]; then
    IFS=$sep read -rA version1 <<< "${verstr1//v}"
    IFS=$sep read -rA version2 <<< "${verstr2//v}"
    shear=1
  else
    >&2 echo evangelist supports only bash and zsh.
    exit 1
  fi

  while [[ ${#version1[@]} < ${#version2[@]} ]]; do
    version1+=( 0 )
  done

  while [[ ${#version2[@]} < ${#version1[@]} ]]; do
    version2+=( 0 )
  done

  version1+=( "$suf1" )
  version2+=( "$suf2" )

  for ((i=shear; i<${#version1[@]}+shear; ++i )); do
    if [[ ${version1[$i]} = "${version2[$i]}" ]]; then
      continue
    fi

    if [[ ${version1[$i]} =~ ^[0-9]+$ ]] && [[ ${version2[$i]} =~ ^[0-9]+$ ]]
    then
      [[ ${version1[$i]} -gt ${version2[$i]} ]] && return 0
    else
      [[ ${version1[$i]} > ${version2[$i]} ]] && return 0
    fi

    return 1
  done

  return 0
}


utils::resolve_vim_alternatives () {
  ## Note, this function is called when `HAS nvim && HAS vim` gives `true`.
  ## That means that the system might have both Vim and Neovim installed.
  ## But it is not necessarily the case.

  local alternatives value hint reply
  if alternatives=$(update-alternatives --query vim 2> /dev/null)
  then
    if ! grep -q 'VIM-ALTERNATIVE' .update-list
    then
      value=$(grep 'Value:' <<< "$alternatives" | cut -d ' ' -f2)
      sed -i "/^Installed/i VIM-ALTERNATIVE:$value" .update-list
    fi

    ## 1st condition = there is no way to get value with update-alternatives.
    ## 2nd one = it is already the value we want to see.
    ## In both cases, we don't go futher.
    [[ -z $value ]] || [[ $value =~ nvim ]] && return

    if [[ $(grep -c 'Alternative:' <<< "$alternatives") -ge 2 ]]; then
      ## `_MSG` is local to `controll::install` function
      ## but accessible from `utils::resolve_vim_alternatives`.
      _MSG="sudo update-alternatives --set vim \$(which nvim)"
      return
    fi
  fi

  ## more aggressive way
  case ${SHELL##*/} in
    bash) hint='~/.bashrc' ;;
    zsh) hint='$ZDOTDIR/.zshrc' ;;
  esac

  read -p "Where to add an alias? [$hint]: " reply
  [[ -z "$reply" ]] && reply=$(eval echo $hint)
  ## The following lines also cover the case
  ## when it is not possible to set Vim's alternative.
  echo -e '\nalias vim=nvim # added by EVANGELIST' >> "$reply"
  echo -e "alias vimdiff='nvim -d' # added by EVANGELIST" >> "$reply"
  ## ex (improved Ex mode) and view (read only mode):
  # echo -e "alias ex='nvim -E' # added by EVANGELIST" >> "$reply"
  # echo -e "alias view='nvim -R' # added by EVANGELIST" >> "$reply"
}
