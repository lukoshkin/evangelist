#!/bin/bash

# Mason Reinstall Script
# CLI wrapper around user.mason-reinstall (conf/nvim/edge/lua/user/mason-reinstall.lua)

set -euo pipefail

# Configuration
EVANGELIST_DIR="${EVANGELIST:-$HOME/.config/evangelist}"
MASON_PACKAGES_FILE="$EVANGELIST_DIR/mason-packages.txt"
LOG_FILE="$HOME/.local/share/nvim/mason-reinstall.log"
WAIT_TIMEOUT_MS=600000 # 10 minutes

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# Function to check if Neovim is available
check_nvim() {
    if ! command -v nvim &>/dev/null; then
        log_error "Neovim is not installed or not in PATH"
        exit 1
    fi
}

# Function to check if mason-packages.txt exists
check_packages_file() {
    if [[ ! -f "$MASON_PACKAGES_FILE" ]]; then
        log_error "Mason packages file not found: $MASON_PACKAGES_FILE"
        log_error "Please create the file with package names (one per line)"
        exit 1
    fi
}

# Runs a Lua call against user.mason-reinstall in headless Neovim, waits for
# the (async) install(s) it triggers to finish via a completion callback,
# prints a "total=.. installed=.. skipped=.. failed=.. missing=.." summary
# line, and exits 3 if anything failed or was missing from the registry.
#
# $1: a Lua expression that, given a local `mason_reinstall` module and a
#     `on_summary` callback, triggers the install(s), e.g.:
#     "mason_reinstall.reinstall_from_logfile(on_summary)"
run_headless_lua() {
    local lua_call="$1"

    nvim --headless --noplugin -u NONE -c "
        lua << EOF
        vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/mason.nvim')
        vim.opt.rtp:prepend(vim.fn.stdpath('config') .. '/lua')

        local mason_reinstall = require('user.mason-reinstall')
        local done, summary = false, nil
        local function on_summary(s)
            summary = s
            done = true
        end

        local call_ok, call_err = pcall(function()
            $lua_call
        end)

        if not call_ok then
            print('Error: ' .. tostring(call_err))
            vim.cmd('cquit 1')
        end

        vim.wait($WAIT_TIMEOUT_MS, function() return done end, 200)

        if not done then
            print('Timed out waiting for installs to finish')
            vim.cmd('cquit 1')
        end

        print(string.format(
            'total=%d installed=%d skipped=%d failed=%d missing=%d',
            summary.total, summary.installed, summary.skipped, summary.failed, summary.missing
        ))

        if summary.failed > 0 or summary.missing > 0 then
            vim.cmd('cquit 3')
        end

        vim.cmd('qall')
EOF
    " 2>&1 | tee -a "$LOG_FILE"

    return "${PIPESTATUS[0]}"
}

# Function to reinstall packages that failed to install
reinstall_failed() {
    log_info "Reinstalling Mason packages that previously failed to install..."

    local exit_code=0
    run_headless_lua "mason_reinstall.reinstall_from_logfile(on_summary)" || exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_success "Reinstall of failed packages completed"
    else
        log_error "Reinstall of failed packages finished with exit code $exit_code"
        return $exit_code
    fi
}

# Function to install missing packages only
install_missing() {
    log_info "Installing missing Mason packages..."
    log_info "Using packages file: $MASON_PACKAGES_FILE"

    local exit_code=0
    run_headless_lua "mason_reinstall.reinstall_from_evnfile(on_summary)" || exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_success "Install missing completed successfully"
    else
        log_error "Install missing finished with exit code $exit_code"
        return $exit_code
    fi
}

# Function to force reinstall a specific package
force_reinstall_package() {
    local package_name="$1"
    log_info "Force reinstalling package: $package_name"

    local exit_code=0
    run_headless_lua "mason_reinstall.force_reinstall_package('$package_name', on_summary)" || exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_success "Package $package_name force reinstall completed"
    else
        log_error "Package $package_name force reinstall finished with exit code $exit_code"
        return $exit_code
    fi
}

# Function to show package list
show_packages() {
    log_info "Packages configured for installation:"
    if [[ -f "$MASON_PACKAGES_FILE" ]]; then
        cat "$MASON_PACKAGES_FILE" | grep -v '^#' | grep -v '^$' | while read -r package; do
            # Handle package names with aliases (e.g., "dockerfile-language-server dockerls")
            main_package=$(echo "$package" | awk '{print $1}')
            echo "  - $main_package"
        done
    else
        log_error "Packages file not found: $MASON_PACKAGES_FILE"
    fi
}

# Function to show usage
show_usage() {
    cat <<EOF
Mason Reinstall Script

USAGE:
    $(basename "$0") [COMMAND] [OPTIONS]

COMMANDS:
    reinstall-failed        Reinstall packages that mason.log recorded as failed
    install-missing         Install packages from mason-packages.txt that aren't installed yet
    force-package <name>    Force reinstall a specific package regardless of its current state
    list                    Show configured packages
    help                    Show this help message

EXAMPLES:
    $(basename "$0") reinstall-failed
    $(basename "$0") install-missing
    $(basename "$0") force-package lua-language-server
    $(basename "$0") list

FILES:
    Packages file: $MASON_PACKAGES_FILE
    Log file: $LOG_FILE

ENVIRONMENT VARIABLES:
    EVANGELIST           Path to evangelist directory (default: \$HOME/.config/evangelist)

EXIT CODES:
    0: Success
    1: General error (missing dependencies, file not found, timed out waiting for installs)
    3: One or more packages failed to install or weren't found in the registry
EOF
}

# Main function
main() {
    # Create log file directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"

    # Initialize log file
    echo "=== Mason Reinstall Script Started at $(date) ===" >>"$LOG_FILE"

    case "${1:-help}" in
    "reinstall-failed" | "--reinstall-failed" | "-r")
        check_nvim
        reinstall_failed
        ;;
    "install-missing" | "--install-missing" | "-i")
        check_nvim
        check_packages_file
        install_missing
        ;;
    "force-package" | "--force-package" | "-p")
        if [[ -z "${2:-}" ]]; then
            log_error "Package name is required for force-package command"
            echo "Usage: $0 force-package <package-name>"
            exit 1
        fi
        check_nvim
        force_reinstall_package "$2"
        ;;
    "list" | "--list" | "-l")
        show_packages
        ;;
    "help" | "--help" | "-h" | *)
        show_usage
        ;;
    esac

    echo "=== Mason Reinstall Script Finished at $(date) ===" >>"$LOG_FILE"
}

# Execute main function with all arguments
main "$@"
