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

evangelist() {
  local launcher="$EVANGELIST/evangelist.sh"
  if [[ $(uname) = Darwin && -x "$EVANGELIST/evangelist.macos.zsh" ]]; then
    launcher="$EVANGELIST/evangelist.macos.zsh"
  fi

  "$launcher" "$@"
}

evn() {
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

_has_external_command() {
  if [[ -n $BASH_VERSION ]]; then
    type -P "$1" &>/dev/null
    return
  fi

  whence -p "$1" &>/dev/null
}

alias gl='git log'
alias gd='git diff'
alias gds='git diff --staged'
alias gs='git switch'
alias glpr='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
alias avante='nvim -c "lua vim.defer_fn(function()require(\"avante.api\").zen_mode()end, 100)"'

o() {
  command xdg-open "$@"
}

gswt() {
      if git diff --quiet; then
          echo "No unstaged changes to stash"
          return 1
      fi

      ## Temporarily commit staged changes and then restore
      git commit --no-verify -m "TEMP_STAGED" --allow-empty -q
      git stash push -m "${1:-unstaged changes}"
      git reset --soft HEAD~1 -q
  }

gsti() {
  if git diff --staged --quiet; then
    echo "No staged changes to stash"
    return 1
  fi

  git stash push --staged -m "${1:-staged changes}"
}

gsm() {
  if git show-ref --quiet refs/heads/master; then
    git switch master
    return
  fi

  git switch main
}

gsd() {
  if git show-ref --quiet refs/heads/develop refs/remotes/origin/develop; then
    git switch develop
    return
  fi

  git switch dev
}

gpub() {
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD)
  git push -u origin "$branch"
}

## Open the last file closed:
# alias v="vim +'e #<1'"
# alias v="vim +'execute \"normal \<C-P>\<Enter>\"'"
v() {
  if [[ $# -eq 1 && -d $1 ]]; then
    ## On a directory, open nvim-tree rooted at it instead of a blank
    ## buffer (netrw is disabled). 'current_window' makes the tree fill
    ## the window rather than splitting off a side panel next to an empty
    ## buffer. The subshell keeps the caller's CWD unchanged; nvim-tree's
    ## root follows nvim's CWD.
    (cd "$1" && vim -c "lua require('nvim-tree.api').tree.open({ current_window = true })")
    return
  fi

  if [[ $# -gt 0 ]]; then
    vim "$@"
    return
  fi

  if [[ -f "$XDG_CONFIG_HOME/init.vim" ]]; then
    vim +'execute "normal \<C-P>\<Enter>"'
  else
    vim +"normal ${V_CMD:-\ff}"
  fi
}

alias vv='V_CMD=\\fo v'
alias vg='V_CMD=\\fg v'
alias _vimrc="vim $XDG_CONFIG_HOME/nvim/init.*"
alias vimrc="vim $EVANGELIST/custom/custom.vim"

## Folder stack navigation.
alias d='dirs -v'
alias G='gg 0'

gg() {
  if [[ -z $1 ]]; then
    pushd +1 &>/dev/null
    [[ $? -ne 0 ]] && echo Singular dir stack || :

  elif [[ $1 = 0 ]]; then
    pushd -0 >/dev/null

  elif [[ $1 =~ ^[0-9]+$ ]]; then
    pushd +$1 >/dev/null

  elif [[ $1 =~ ^-[0-9]+$ ]]; then
    popd +${1:1}

  else
    echo Wrong args
  fi
}

tmp() {
  cd /tmp || return
  [[ -z $1 ]] && return
  eval "$*"
  cd - >/dev/null
}

tarz() {
  [[ -z $1 ]] && {
    echo Path must be provided!
    exit 1
  }

  local name=${1##*/}
  tar czf "$name.tar.gz" "$@"
}

_math() {
  ## _ANS can be reused later.
  _ANS=$(($*))
  echo $_ANS
}

st() { # git STatus or STorage
  if [[ -n $1 ]] || ! git status 2>/dev/null; then
    if [[ $PWD = "$HOME" ]]; then
      echo "You are in the home directory."
      return 1
    fi
    command du -hm --max-depth=1 "${@:-.}" | sort -h -r
  fi
}

if [[ $_shell = bash ]]; then
  ## Repeat the last command in Bash (just like in Zsh).
  r() {
    fc -s
  }

  ## Similar to Fish's `math`.
  alias math='_math'
else
  alias math='noglob _math'
fi

_mangle_name() {
  local name=$1
  no=$(sed -nr 's;.*\(([0-9]+)\)(\.[^\.]+)?$;\1;p' <<<"$name")

  if [[ -z $no ]]; then
    if [[ $name != *.* || -d /tmp/$name ]]; then
      name+='(1)'
    else
      name=$(sed -r 's;(.*)(\.[^\.]+);\1(1)\2;' <<<"$name")
    fi
  else
    copy_no=$((no + 1))
    name=$(sed -r "s;(.*\()$no(\)(\.[^\.]+)?)\$;\1$copy_no\2;" <<<"$name")
  fi

  echo "$name"
}

mv() {
  ## Something like 'gvfs-trash' implementation.
  ## When passing just one argument, it "removes" file or folder
  ## backing it up at the "trash bin" (/tmp).

  ## Some of concerns:
  ## - /tmp is a limited in size partition
  ## - `while`-loop
  command -v realpath &>/dev/null
  local code=$?

  if [[ $# != 1 || $code -ne 0 ]]; then
    command mv "$@"
  else
    local no copy_no parent
    local name=${1%/} landing=/tmp
    local loop_cnt=0 max_loop_cnt=100

    name=${name##*/}
    parent=$(realpath "$(dirname "$name")")

    if [[ $parent = "/tmp" ]]; then
      echo "You can't use one-arg mv cmds in /tmp dir."
      return 1
    fi

    while [[ -e /tmp/$name ]]; do
      name=$(_mangle_name "$name")

      ((loop_cnt++))
      if [[ $loop_cnt -ge $max_loop_cnt ]]; then
        echo "EVANGELIST's Impl.error: infinite loop"
        return 1
      fi
    done

    [[ $name != "$1" ]] && landing+="/$name"

    command mv "$1" "$landing" &&
      echo "$1 has been moved to $landing."
  fi
}

## Some other functions that might be useful.
md() {
  mkdir -p "$@"
  [[ $# -gt 1 ]] && return 1
  cd "$1"
}

dtree() {
  local w8
  [[ -n $1 ]] && w8=$1 || w8=.5

  timeout $w8 find . ! -path '*/\.*' -type d &>/dev/null

  ## 124 - command timed out
  if [[ $? -eq 124 ]]; then
    echo 'Try to run it in one of subfolders.'
    return
  fi

  # ls -R | grep ":$" | sed -e 's/:$//' \
  find . -not -path '*/.*' -type d -print | sed -e \
    's;[^-][^\/]*\/;--;g' -e 's;^;   ;' -e 's;-;|;'
}

tree() {
  if ! _has_external_command tree; then
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

swap() {
  [[ -z $1 || -z $2 ]] && {
    echo 'Requires src and dest'
    return 1
  }
  local bak="/tmp/${1##*/}.bak"

  cp -R "$1" "$bak" &&
    command rm -rf "$1" &&
    mv "$2" "$1" &&
    mv "$bak" "$2"
}

bak() {
  local dst
  for file in "$@"; do
    dst=$(basename "$file")
    [[ -e bak.$file ]] && {
      echo "bak.$file already exists"
      return 1
    }
    cp -r "$file" "bak.${dst#.}"
  done
}

_think_before() {
  local nsec=$1
  while [[ $((nsec -= 1)) -gt 0 ]]; do
    echo "You have $nsec second(s) to change your mind"
    sleep 1
  done
}

rm() {
  if [[ " $* " =~ ' -rf ' ]]; then
    _think_before 5
  fi
  command rm -I "$@"
}

vrmswp() {
  [[ -z $1 ]] && {
    echo "Pass the name of swap file to delete."
    return 1
  }
  local swp=${1//\//%}
  rm "$XDG_STATE_HOME/nvim/swap/"*$swp*
}

## archview — serve docs/architecture/ (from the nearest ancestor) over a
## local HTTP server with a generated index page that renders the README.md
## aggregator and links to the topic .html files. Topic files are exposed
## via symlinks in a temp dir; the source directory is not mutated. Markdown
## rendering tries `markdown`, `markdown-it-py`, `mistune`, then `pandoc`;
## falls back to escaped raw <pre> if none are installed. Ctrl+C stops the
## server and removes the temp dir. Port: $ARCHVIEW_PORT if set (errors if
## busy); otherwise tries 8765 then asks the OS for any free port.
archview() {
  local dir port pid tmp project src
  dir=$(pwd)
  while [ "$dir" != "/" ] && [ ! -d "$dir/docs/architecture" ]; do
    dir=$(dirname "$dir")
  done
  if [ ! -d "$dir/docs/architecture" ]; then
    echo "archview: no docs/architecture/ found in $(pwd) or any ancestor" >&2
    return 1
  fi
  src="$dir/docs/architecture"
  if [ -n "${ARCHVIEW_PORT:-}" ]; then
    port=$ARCHVIEW_PORT
  else
    port=8765
    python3 -c "import socket; s=socket.socket(); s.bind(('127.0.0.1', $port)); s.close()" 2>/dev/null \
      || port=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')
  fi
  project=$(basename "$dir")
  tmp=$(mktemp -d -t archview.XXXXXX)
  find "$src" -maxdepth 1 -type f -name '*.html' -print0 \
    | while IFS= read -r -d '' f; do ln -s "$f" "$tmp/"; done
  _archview_render_index "$src" "$project" > "$tmp/index.html"
  echo "archview: serving $src (via $tmp) on http://127.0.0.1:$port"
  (cd "$tmp" && exec python3 -m http.server "$port" --bind 127.0.0.1) &
  pid=$!
  trap "kill $pid 2>/dev/null; command rm -rf '$tmp'; trap - INT TERM HUP EXIT" INT TERM HUP EXIT
  sleep 0.5
  if ! kill -0 $pid 2>/dev/null; then
    echo "archview: server failed to start on port $port (already in use?)" >&2
    return 1
  fi
  o "http://127.0.0.1:$port" 2>/dev/null
  wait $pid
}

_archview_md_to_html() {
  local md
  md=$(cat)
  if python3 -c "import markdown" 2>/dev/null; then
    printf '%s' "$md" | python3 -c "import sys, markdown; sys.stdout.write(markdown.markdown(sys.stdin.read(), extensions=['tables', 'fenced_code']))"
    return
  fi
  if python3 -c "import markdown_it" 2>/dev/null; then
    printf '%s' "$md" | python3 -c "import sys; from markdown_it import MarkdownIt; sys.stdout.write(MarkdownIt('commonmark').enable('table').render(sys.stdin.read()))"
    return
  fi
  if python3 -c "import mistune" 2>/dev/null; then
    printf '%s' "$md" | python3 -c "import sys, mistune; sys.stdout.write(mistune.html(sys.stdin.read()))"
    return
  fi
  if command -v pandoc >/dev/null; then
    printf '%s' "$md" | pandoc -f markdown -t html
    return
  fi
  printf '<p><em>(No Markdown library or pandoc found; showing raw README.)</em></p>\n<pre>'
  printf '%s' "$md" | python3 -c "import sys, html; sys.stdout.write(html.escape(sys.stdin.read()))"
  printf '</pre>\n'
}

_archview_render_index() {
  local src=$1
  local project=$2
  local readme="$src/README.md"
  local rendered=""
  [ -f "$readme" ] && rendered=$(_archview_md_to_html < "$readme")
  cat <<HEAD
<!doctype html>
<html><head>
<meta charset="utf-8">
<title>Architecture — $project</title>
<style>
body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; max-width: 900px; margin: 2em auto; padding: 0 1em; color: #222; line-height: 1.5; }
h1, h2 { border-bottom: 1px solid #ddd; padding-bottom: .3em; }
table { border-collapse: collapse; }
th, td { border: 1px solid #ddd; padding: .4em .8em; }
code { background: #f4f4f4; padding: .1em .3em; border-radius: 3px; }
pre { background: #f4f4f4; padding: 1em; overflow-x: auto; }
a { color: #0366d6; text-decoration: none; }
a:hover { text-decoration: underline; }
.topics { list-style: none; padding: 0; }
.topics li { margin: .3em 0; }
.topics li::before { content: "📄 "; }
</style>
</head><body>
<h1>Architecture — $project</h1>
<section>$rendered</section>
<h2>Topic files</h2>
<ul class="topics">
HEAD
  find "$src" -maxdepth 1 -type f -name '*.html' -print0 | sort -z \
    | while IFS= read -r -d '' f; do
        name=$(basename "$f")
        echo "  <li><a href=\"$name\">$name</a></li>"
      done
  cat <<'TAIL'
</ul>
</body></html>
TAIL
}

## https://stackoverflow.com/questions/1527049
join_by() {
  local d=$1 f=$2
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

(which tmux &>/dev/null &&
  grep -qE '^n?vim' "$EVANGELIST/.update-list" &&
  grep -q '^source .*slime\.vim' "$XDG_CONFIG_HOME/nvim/init.vim" &&
  grep -q '^source .*ipython\.vim' "$XDG_CONFIG_HOME/nvim/init.vim") \
  &>/dev/null && source "$EVANGELIST/conf/tmux/templates.sh"

[[ $(uname) = Darwin && -f "$EVANGELIST/conf/bash/aliases-functions.macos.sh" ]] \
  && source "$EVANGELIST/conf/bash/aliases-functions.macos.sh"

## Save to use from the interactive shell?
# unset _shell
