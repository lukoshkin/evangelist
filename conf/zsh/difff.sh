#!/bin/bash

## TODO: add a function with a help message.
# diff "$@" || help_msg

function difff () {
  local long_opts='trim-cnt:,folder:,mode:,staged,dry-run,add-new'
  local short_opts='t:,d:,m:,s,n,a'

  params=$(getopt -o $short_opts  -l $long_opts --name "$0" -- "$@")
  [[ $? -ne 0 ]] && { echo No args. Aborting..; return; }
  eval set -- $params
  unset params

  local staged dry_run add_new mode folder trim_cnt
  while [[ $1 != -- ]]; do
    case $1 in
      -s|--staged)    staged=--staged; shift 1 ;;
      -n|--dry-run)   dry_run=yes; shift 1 ;;
      -a|--add-new)   add_new=yes; shift 1 ;;
      -m|--mode)      mode=$2; shift 2;;
      -d|--folder)    folder=./$2; shift 2 ;;
      -t|--trim-cnt)  trim_cnt=$2; shift 2 ;;

      *) echo Impl.error; return 1 ;;
    esac
  done

  shift 1
  [[ $# -eq 0 ]] && { echo Prefix not set; return 1; }

  local prefix=$1
  ! [[ -d $prefix ]] && { echo Prefix $prefix not found; return 1; }
  ! [[ -d ${folder:=.} ]] && { echo Folder $folder not found; return 1; }

  if [[ ${mode:=git} != git ]] && [[ $mode != folder ]]; then
    echo Invalid mode: $mode
    return 1
  fi

  declare -a files
  if [[ $mode = folder ]]; then
    files=( ${folder%/}/**/* )
  else
    git status &> /dev/null || { echo Not a git project.; return 1; }
    files=( $(git diff $staged --name-only "$folder") )
  fi

  if [[ -z $trim_cnt ]]; then
    trim_cnt=0
  else
    (( trim_cnt ++ ))
  fi

  echo "$folder .vs. $prefix"
  echo

  local file find_out desc
  declare -a exclude
  if [[ -n $add_new ]]; then
    for counter in "${prefix%/}"/**/*; do
      file=${folder%/}/${counter/$prefix/}
      if [[ -n ${exclude[*]} ]]; then
        [[ $file =~ ($(IFS=\|; echo "${exclude[*]}")) ]] && continue
      fi

      ## constructing `file` variable may leave double slash (//),
      ## which `find` command does not handle.
      find_out=$(find "$folder" -type f -wholename "${file/\/\//\/}")

      if [[ -z $find_out ]]; then
        [[ -d $counter ]] && continue
        [[ -n $dry_run ]] && { echo "NEW: ${counter}"; continue; }

        desc=
        echo "Not in project: $counter"
        desc+='[c] copy to project\t'
        desc+='[r] remove from counterpart\t'
        desc+='[e] exclude parent dir of the current file\n'
        desc+='Press the corresponding key to take an action.\n'
        desc+='Or any other key to continue.\n'
        echo -e $desc

        # read -srk1    # zsh syntaxis
        read -srn1    # bash syntaxis
        case $REPLY in
          c)
            mkdir -p "$(dirname "$file")"
            cp "$counter" "$file" && echo Copied!
            ;;
          r)
            # read -srk1 '?Confirm deletion - [yN] '    # zsh syntaxis
            read -srn1 -p 'Confirm deletion - [yN] '    # bash syntaxis
            [[ $REPLY =~ [yY] ]] && rm "$counter"
            echo
            ;;
          e)
            exclude+=( "$(dirname "$file")" )
            ;;
          *)
        esac
      fi
    done
  fi

  local counter
  for file in "${files[@]}"; do
    counter=$(sed -r "s;([^\/]+\/){$trim_cnt}(.*);\2;" <<< "$file")
    counter="${prefix%/}/$counter"

    [[ $mode = folder ]] && [[ -d $counter ]] && continue

    ## Why check `file`? ─ `git diff` reports also deleted.
    ! [[ -f $file ]] && { echo Not in project: $file; continue; }
    ! [[ -f $counter ]] && { echo Not in couterpart: $counter; continue; }

    if [[ -n $dry_run ]]; then
      echo $file -- $counter
      continue
    fi

    cmp -s $file $counter && continue
    vimdiff $file $counter
  done
}
