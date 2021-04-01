#!/bin/bash

# This function should be called only once
# within the body of an installation function
back_up_original_configs () {
  if ! grep -q "^$1" .update-list
  then
    echo $1 >> .update-list
    shift

    local m v n
    for arg in $@
    do
      m=$(cut -d ':' -f1 <<< $arg) 
      v=$(cut -d ':' -f2 <<< $arg)
      n=$(cut -d ':' -f3 <<< $arg)

      v=$(eval echo $v)
      n=$(eval echo $n)
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


dummy_v1_gt_v2 () {
  declare -a version1 version2
  if [[ $(readlink /proc/$$/exe) == *bash ]]
  then
    IFS='.' read -ra version1 <<< $1
    IFS='.' read -ra version2 <<< $2
    local shear=0
  elif [[ $(readlink /proc/$$/exe) == *zsh ]]
  then
    IFS='.' read -rA version1 <<< $1
    IFS='.' read -rA version2 <<< $2
    local shear=1
  else
    ECHO2 "Don't support this shell."
    exit
  fi

  for ((i=shear; i<3+shear; ++i ))
  do
    if [[ ${version1[$i]} == ${version2[$i]} ]]
    then
      continue
    fi

    if [[ ${version1[$i]} =~ ^[0-9]+$ && ${version2[$i]} =~ ^[0-9]+$ ]]
    then
      [[ ${version1[$i]} -gt ${version2[$i]} ]] && return 0
    else
      [[ ${version1[$i]} > ${version2[$i]} ]] && return 0
    fi

    break
  done
  return 1
}

