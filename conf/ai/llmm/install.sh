#!/usr/bin/env bash
# install.sh — build llama.cpp from source + install llmm deps, then wire up
# the llmm command. Bash 3.2-safe (macOS system bash). Idempotent.
#
# Usage: install.sh [--force] [--rebuild] [--backend cuda|vulkan|cpu]
set -euo pipefail

LLMM_SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/llmm"
CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/llmm"
BIN_DST="$HOME/.local/bin/llmm"

FORCE=false; REBUILD=false; BACKEND="${LLMM_BACKEND:-}"
while [ $# -gt 0 ]; do
  case "$1" in
    --force) FORCE=true; shift ;;
    --rebuild) REBUILD=true; shift ;;
    --backend) BACKEND="$2"; shift 2 ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
done

say()  { printf '==> %s\n' "$*"; }
warn() { printf 'warn: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }
has()  { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"; ARCH="$(uname -m)"
say "platform: $OS/$ARCH"

# --- base deps ---------------------------------------------------------------
ensure_base_deps() {
  has git   || die "git is required"
  has curl  || die "curl is required"
  if ! has cmake; then
    if [ "$OS" = Darwin ]; then die "cmake required: brew install cmake"; fi
    die "cmake required (e.g. apt install cmake / dnf install cmake)"
  fi
  if [ "$OS" = Darwin ] && ! has cc; then
    die "C toolchain required: xcode-select --install"
  fi
}

# --- backend selection -------------------------------------------------------
detect_backend() {
  if [ "$OS" = Darwin ]; then echo metal; return; fi
  if has nvidia-smi; then echo cuda; else echo cpu; fi
}

choose_backend() {
  if [ "$OS" = Darwin ]; then BACKEND=metal; return; fi
  local default; default="$(detect_backend)"
  if [ -n "$BACKEND" ]; then return; fi
  # Non-interactive (no TTY): take the detected default silently.
  if [ ! -t 0 ]; then BACKEND="$default"; say "backend: $BACKEND (auto, non-interactive)"; return; fi
  printf 'compute backend [cuda|vulkan|cpu] (default %s): ' "$default"
  read -r BACKEND || true
  [ -n "$BACKEND" ] || BACKEND="$default"
  # lowercase without ${var,,} (bash 3.2-safe): use tr.
  BACKEND="$(printf '%s' "$BACKEND" | tr '[:upper:]' '[:lower:]')"
}

cmake_backend_flags() {
  case "$1" in
    metal)  echo "-DGGML_METAL=ON" ;;
    cuda)   has nvcc || warn "nvcc not found; CUDA build may fail"; echo "-DGGML_CUDA=ON" ;;
    vulkan) echo "-DGGML_VULKAN=ON" ;;
    cpu)    echo "" ;;
    *)      die "unknown backend: $1" ;;
  esac
}

# --- build llama.cpp ---------------------------------------------------------
build_llamacpp() {
  local src="$DATA_DIR/src/llama.cpp"
  mkdir -p "$DATA_DIR/src" "$DATA_DIR/bin"
  if [ ! -d "$src/.git" ]; then
    say "cloning llama.cpp"
    git clone --depth 1 https://github.com/ggml-org/llama.cpp "$src"
  else
    say "updating llama.cpp"
    git -C "$src" pull --ff-only || warn "git pull failed; building current checkout"
  fi
  if $REBUILD; then rm -rf "$src/build"; fi
  local flags; flags="$(cmake_backend_flags "$BACKEND")"
  say "configuring (backend=$BACKEND)"
  # shellcheck disable=SC2086
  cmake -S "$src" -B "$src/build" -DCMAKE_BUILD_TYPE=Release -DLLAMA_CURL=ON $flags
  say "building (this can take several minutes)"
  cmake --build "$src/build" --config Release -j --target llama-server
  # Install the server + shared libs into the XDG bin dir.
  find "$src/build/bin" -maxdepth 1 -type f -name 'llama-server' -exec cp {} "$DATA_DIR/bin/" \;
  find "$src/build/bin" -maxdepth 1 \( -name '*.dylib' -o -name '*.so' -o -name '*.so.*' \) \
    -exec cp {} "$DATA_DIR/bin/" \; 2>/dev/null || true
  [ -x "$DATA_DIR/bin/llama-server" ] || die "build did not produce llama-server"
  say "installed llama-server -> $DATA_DIR/bin"
}

# --- python tooling (uv + huggingface CLI) -----------------------------------
ensure_uv_hf() {
  if ! has uv; then
    say "installing uv"
    curl -LsSf https://astral.sh/uv/install.sh | sh || { warn "uv install failed; pulls will fall back to --hf-repo"; return 0; }
    # uv installs to ~/.local/bin which we expect on PATH.
  fi
  if has uv && ! has hf; then
    say "installing huggingface_hub CLI"
    uv tool install "huggingface_hub[cli]" || warn "hf install failed; pulls will fall back to --hf-repo"
  fi
}

# --- zsh + fzf checks --------------------------------------------------------
ensure_runtime_tools() {
  has zsh || warn "zsh not found — llmm requires zsh at runtime (install it for your platform)"
  has fzf || warn "fzf not found — 'llmm pick' will use a numbered menu"
}

# --- symlink + seed ----------------------------------------------------------
link_and_seed() {
  mkdir -p "$HOME/.local/bin" "$CFG_DIR" "$DATA_DIR/models"
  if [ -e "$BIN_DST" ] && [ ! -L "$BIN_DST" ]; then
    if $FORCE; then mv "$BIN_DST" "$BIN_DST.pre-evangelist.bak"
    else die "refusing to overwrite regular file $BIN_DST (re-run with --force)"; fi
  fi
  ln -sfn "$LLMM_SRC_DIR/llmm" "$BIN_DST"
  say "linked $BIN_DST -> $LLMM_SRC_DIR/llmm"
  if [ ! -f "$CFG_DIR/config.zsh" ]; then
    cp "$LLMM_SRC_DIR/config.default.zsh" "$CFG_DIR/config.zsh"
    say "seeded $CFG_DIR/config.zsh"
  fi
}

main() {
  ensure_base_deps
  choose_backend
  if $REBUILD || [ ! -x "$DATA_DIR/bin/llama-server" ]; then build_llamacpp; else say "llama-server already built (use --rebuild to force)"; fi
  ensure_uv_hf
  ensure_runtime_tools
  link_and_seed
  say "done. Run 'llmm' to start, or 'llmm help'."
  case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) warn "add ~/.local/bin to PATH";; esac
}
main
