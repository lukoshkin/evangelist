#!/bin/bash

# Common functions shared between conda-autoenv.sh and venv-autoenv.sh

up_hierarchy_search() {
  if [[ -z $1 || -z $2 ]]; then
    echo up_hierarchy_search: missing args.
    echo 'Try: up_hierarchy_search <dir> <file>`'
    return 1
  fi

  ## `max_recursion_depth` to avoid infinite recursion
  local max_recursion_depth=100

  _up_hierarchy_search() {
    [[ $1 = / ]] && return 1
    ## 'ls $1/$2' is simpler but doesn't fit zsh
    ## (by default, zsh prints an error msg to stdout on a failed globbing).
    local found_evnfiles
    found_evnfiles=$(find "$1" -maxdepth 1 -type f -name "$2")

    if [[ -n $found_evnfiles ]] ||
      [[ $((max_recursion_depth--)) -le 0 ]]; then
      echo "$found_evnfiles"
      return
    fi

    _up_hierarchy_search "$(dirname "$1")" "$2"
  }

  local parent
  parent=$(realpath "$1" 2>/dev/null) ||
    parent=$(readlink -f "$1" 2>/dev/null) || return

  _up_hierarchy_search "$parent" "$2"
}

_get_array_index() {
  if [[ -n $ZSH_VERSION ]]; then
    if [[ -o KSH_ARRAYS ]]; then
      echo 0 # 0-based indexing when KSH_ARRAYS is set
    else
      echo 1 # 1-based indexing when KSH_ARRAYS is unset (default)
    fi
  else
    echo 0 # bash always uses 0-based indexing
  fi
}

# Setup shell hooks for autoenv functionality
# Usage: _setup_autoenv_hooks <function_name>
# where function_name is the specific autoenv function to call (e.g., _conda_autoenv_bash)
_setup_autoenv_hooks() {
  local bash_function="$1"
  local zsh_function="$2"

  if [[ -z $bash_function || -z $zsh_function ]]; then
    >&2 echo "Error: _setup_autoenv_hooks requires both bash and zsh function names"
    return 1
  fi

  if [[ -n $ZSH_VERSION ]]; then
    ## 'chpwd' hook fires when the directory is changed.
    autoload -U add-zsh-hook
    add-zsh-hook chpwd "$zsh_function"
    ## Run when starting a new shell instance.
    "$zsh_function"
  elif [[ -n $BASH_VERSION ]]; then
    ## PROMPT_COMMAND contents is executed before each prompt.
    ## However, we want to be able to run `deactivate` in a directory
    ## with .autoenv-evn.* file. To this end, we use PREV_WORK_DIR variable
    ## to run the autoenv function only when the directory is changed.

    ## To call autoenv on the shell startup, we initialize
    ## PREV_WORK_DIR with non-existent path
    PREV_WORK_DIR=/-/
    PROMPT_COMMAND="$bash_function; $PROMPT_COMMAND"
  else
    >&2 echo 'Impl.error: autoenv works only with bash or zsh.'
    return 1
  fi
}

# Common function to process found autoenv files
# Usage: _process_autoenv_files <directory> [first_elem_id]
# Returns: array of found files in global variable 'found'
_process_autoenv_files() {
  [[ $AUENV_SHELL == false ]] && return

  [[ -z $1 ]] && {
    echo Not enough args provided
    return 1
  }

  local first_elem_id=${2:-$(_get_array_index)}
  found=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && found+=("$line")
  done < <(up_hierarchy_search "$1" '.autoenv-evn.*')

  if [[ -z ${found[*]} ]]; then
    return 1 # No files found
  fi

  if [[ ${#found[@]} -gt 1 ]]; then
    echo There are several autoenv-files found:
    echo "${found[*]}"
    echo
    echo Note, the autoenv-script tries to activate only the environment
    echo "corresponding to the first autoenv-file listed by \`ls\`."
    echo Please, keep only one '.autoenv-evn.*'
    echo
  fi

  ## Return the first found file via global variable
  _AE_EVNFILE="${found[$first_elem_id]}"
  return 0
}

# Safe file removal for marker files
_remove_marker_files() {
  for file in .autoenv-evn.*; do
    [[ -f "$file" ]] && rm "$file"
  done 2>/dev/null
}

# Check if a command is available
_command_exists() {
  command -v "$1" >/dev/null 2>&1
}
