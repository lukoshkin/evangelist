#!/usr/bin/env bash
# Configure pyproject.toml for uv — idempotent bootstrap.
#
# Behavior:
#   * If no pyproject.toml: runs `uv init --bare`
#   * For each requested dep, adds it via `uv add --no-sync` only if not already
#     listed anywhere in pyproject.toml (name match, version-agnostic)
#   * If pyproject.toml has no [tool.ruff*] block, appends one. With --include
#     the appended block is [tool.ruff] include = [...] + [tool.ruff.lint].
#     Without --include it is just a [tool.ruff.lint] marker.
#   * Never modifies an existing [tool.ruff*] block — the slash command is
#     responsible for updating an already-configured project.
#   * Never runs `uv sync` — the venv is not touched.

set -euo pipefail

deps=""
dev_deps="ruff"
include=""
python_version=""

usage() {
  cat <<'EOF'
Usage: uv-setup.sh [OPTIONS]

Options:
  --deps pkg1,pkg2       Comma-separated runtime deps to add (if missing)
  --dev-deps pkg3,pkg4   Comma-separated dev deps to add (default: "ruff")
  --include glob1,glob2  Ruff include patterns, e.g. "src/**/*.py,tests/**/*.py"
  --python VERSION       Python version passed to `uv init --bare`
  -h, --help             Show this help

Exit codes:
  0  success (including "nothing to do")
  1  argument error
  2  uv command failed
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --deps) deps="$2"; shift 2 ;;
    --dev-deps) dev_deps="$2"; shift 2 ;;
    --include) include="$2"; shift 2 ;;
    --python) python_version="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'uv-setup: unknown arg: %s\n' "$1" >&2; usage >&2; exit 1 ;;
  esac
done

trim() {
  local s=$1
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

dep_present() {
  # Match "pkg", "pkg>=0.1", "pkg==1.0", "pkg[extra]" in any quoted form.
  local pkg=$1
  grep -qiE "\"${pkg}(\[|[<>=!~;]|\")" pyproject.toml 2>/dev/null
}

add_missing() {
  local dev=$1 csv=$2
  [[ -z "$csv" ]] && return 0
  local arr pkg pkg_name to_add=()
  IFS=',' read -ra arr <<<"$csv"
  for pkg in "${arr[@]}"; do
    pkg=$(trim "$pkg")
    [[ -z "$pkg" ]] && continue
    pkg_name="${pkg%%[<>=!~\[]*}"
    if dep_present "$pkg_name"; then
      printf '· %s already present\n' "$pkg_name"
    else
      to_add+=("$pkg")
    fi
  done
  if [[ ${#to_add[@]} -gt 0 ]]; then
    local cmd=(uv add --no-sync)
    [[ "$dev" == "1" ]] && cmd+=(--dev)
    cmd+=("${to_add[@]}")
    if ! "${cmd[@]}"; then
      printf 'uv-setup: `uv add` failed\n' >&2
      exit 2
    fi
    local label=runtime
    [[ "$dev" == "1" ]] && label=dev
    printf '+ added %s deps: %s\n' "$label" "${to_add[*]}"
  fi
}

build_include_array() {
  local csv=$1 quoted="" arr p
  IFS=',' read -ra arr <<<"$csv"
  for p in "${arr[@]}"; do
    p=$(trim "$p")
    [[ -z "$p" ]] && continue
    [[ -n "$quoted" ]] && quoted+=", "
    quoted+="\"$p\""
  done
  printf '%s' "$quoted"
}

# 1) Bootstrap pyproject.toml if missing
if [[ ! -f pyproject.toml ]]; then
  init_args=(--bare)
  [[ -n "$python_version" ]] && init_args+=(--python "$python_version")
  if ! uv init "${init_args[@]}"; then
    printf 'uv-setup: `uv init` failed\n' >&2
    exit 2
  fi
  printf '+ created pyproject.toml via uv init --bare\n'
fi

# 2) Add deps that aren't already listed
add_missing 0 "$deps"
add_missing 1 "$dev_deps"

# 3) Append a [tool.ruff*] block if none exists
if grep -q '^\[tool\.ruff' pyproject.toml; then
  printf '· [tool.ruff*] already present (not modified)\n'
elif [[ -n "$include" ]]; then
  quoted=$(build_include_array "$include")
  {
    printf '\n[tool.ruff]\ninclude = [%s]\n\n[tool.ruff.lint]\nselect = ["E", "F", "W", "I", "UP"]\n' "$quoted"
  } >>pyproject.toml
  printf '+ appended [tool.ruff] with include = [%s]\n' "$quoted"
else
  {
    printf '\n[tool.ruff.lint]\nselect = ["E", "F", "W", "I", "UP"]\n'
  } >>pyproject.toml
  printf '+ appended minimal [tool.ruff.lint] block\n'
fi

printf 'uv-setup: done (no venv touched; run `uv sync` when ready).\n'
