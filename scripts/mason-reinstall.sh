#!/bin/bash

# Mason Force Reinstall Script
# This script allows you to force reinstall Mason packages from the command line

set -euo pipefail

# Configuration
EVANGELIST_DIR="${EVANGELIST:-$HOME/.config/evangelist}"
MASON_PACKAGES_FILE="$EVANGELIST_DIR/mason-packages.txt"
LOG_FILE="$HOME/.local/share/nvim/mason-reinstall.log"

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

# Function to force reinstall all packages
force_reinstall_all() {
    log_info "Starting force reinstall of all Mason packages..."
    log_info "Using packages file: $MASON_PACKAGES_FILE"

    # Use Neovim to execute the Lua function
    nvim --headless --noplugin -u NONE -c "
        lua << EOF
        -- Setup basic mason configuration
        vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/mason.nvim')
        vim.opt.rtp:prepend(vim.fn.stdpath('config') .. '/lua')

        -- Load and execute the force reinstall function
        local success, result = pcall(function()
            local mason_reinstall = require('user.mason-reinstall')
            return mason_reinstall.evn_force_reinstall()
        end)

        if success then
            print('Force reinstall completed successfully')
            print('Total: ' .. result.total)
            print('Success: ' .. result.success)
            print('Failed: ' .. result.failed)
            print('Skipped: ' .. result.skipped)
        else
            print('Error during force reinstall: ' .. tostring(result))
            vim.cmd('cquit 1')
        end

        vim.cmd('qall')
EOF
    " 2>&1 | tee -a "$LOG_FILE"

    local exit_code=${PIPESTATUS[0]}
    if [[ $exit_code -eq 0 ]]; then
        log_success "Force reinstall completed successfully"
    else
        log_error "Force reinstall failed with exit code $exit_code"
        return $exit_code
    fi
}

# Function to install missing packages only
install_missing() {
    log_info "Installing missing Mason packages..."
    log_info "Using packages file: $MASON_PACKAGES_FILE"

    nvim --headless --noplugin -u NONE -c "
        lua << EOF
        -- Setup basic mason configuration
        vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/mason.nvim')
        vim.opt.rtp:prepend(vim.fn.stdpath('config') .. '/lua')

        -- Load and execute the install missing function
        local success, result = pcall(function()
            local mason_reinstall = require('user.mason-reinstall')
            return mason_reinstall.evn_install_missing()
        end)

        if success then
            print('Install missing completed successfully')
            print('Total: ' .. result.total)
            print('Success: ' .. result.success)
            print('Failed: ' .. result.failed)
            print('Skipped: ' .. result.skipped)
        else
            print('Error during install missing: ' .. tostring(result))
            vim.cmd('cquit 1')
        end

        vim.cmd('qall')
EOF
    " 2>&1 | tee -a "$LOG_FILE"

    local exit_code=${PIPESTATUS[0]}
    if [[ $exit_code -eq 0 ]]; then
        log_success "Install missing completed successfully"
    else
        log_error "Install missing failed with exit code $exit_code"
        return $exit_code
    fi
}

# Function to force reinstall a specific package
force_reinstall_package() {
    local package_name="$1"
    log_info "Force reinstalling package: $package_name"

    nvim --headless --noplugin -u NONE -c "
        lua << EOF
        -- Setup basic mason configuration
        vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/mason.nvim')
        vim.opt.rtp:prepend(vim.fn.stdpath('config') .. '/lua')

        -- Load and execute the force reinstall function for specific package
        local success, result = pcall(function()
            local mason_reinstall = require('user.mason-reinstall')
            return mason_reinstall.force_reinstall_package('$package_name')
        end)

        if success then
            print('Package $package_name force reinstall initiated successfully')
        else
            print('Error during package $package_name force reinstall: ' .. tostring(result))
            vim.cmd('cquit 1')
        end

        vim.cmd('qall')
EOF
    " 2>&1 | tee -a "$LOG_FILE"

    local exit_code=${PIPESTATUS[0]}
    if [[ $exit_code -eq 0 ]]; then
        log_success "Package $package_name force reinstall initiated successfully"
    else
        log_error "Package $package_name force reinstall failed with exit code $exit_code"
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
Mason Force Reinstall Script

USAGE:
    $(basename "$0") [COMMAND] [OPTIONS]

COMMANDS:
    force-all              Force reinstall all packages from mason-packages.txt
    install-missing        Install only missing packages (skip already installed)
    force-package <name>   Force reinstall a specific package
    list                   Show configured packages
    help                   Show this help message

OPTIONS:
    -v, --verbose         Enable verbose logging
    -q, --quiet          Suppress output (errors only)

EXAMPLES:
    $(basename "$0") force-all
    $(basename "$0") install-missing
    $(basename "$0") force-package lua-language-server
    $(basename "$0") list

FILES:
    Packages file: $MASON_PACKAGES_FILE
    Log file: $LOG_FILE

ENVIRONMENT VARIABLES:
    EVANGELIST           Path to evangelist directory (default: \$HOME/.config/evangelist)
EOF
}

# Main function
main() {
    # Create log file directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"

    # Initialize log file
    echo "=== Mason Reinstall Script Started at $(date) ===" >>"$LOG_FILE"

    case "${1:-help}" in
    "force-all" | "--force-all" | "-f")
        check_nvim
        check_packages_file
        force_reinstall_all
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
