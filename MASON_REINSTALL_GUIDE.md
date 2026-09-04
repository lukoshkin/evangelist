# Mason Reinstall Guide

This guide explains how to use the Mason reinstall tooling to recover from
package installation failures.

## Overview

Two components:
1. **Lua module** (`conf/nvim/edge/lua/user/mason-reinstall.lua`) - core functionality
2. **Bash script** (`scripts/mason-reinstall.sh`) - CLI wrapper for command-line usage

All installs are triggered through Mason's own `pkg:install{ force = true }`,
which is asynchronous - inside Neovim, functions return immediately and the
install continues in the background; the CLI script blocks (via `vim.wait`)
until Mason reports each triggered install has finished, then prints a
summary and exits.

## Quick Start

### 1. Reinstall packages that failed to install
```bash
~/.config/evangelist/scripts/mason-reinstall.sh reinstall-failed
```
Scans Neovim's `mason.log` for packages that failed (a plain install
failure or a lockfile conflict), and reinstalls only the ones that are
still not installed now. This is what `:MasonReinstall` runs inside Neovim.

### 2. Install missing packages only
```bash
# Installs whatever from mason-packages.txt isn't installed yet; leaves
# already-installed packages alone.
~/.config/evangelist/scripts/mason-reinstall.sh install-missing
```

### 3. Force reinstall a specific package
```bash
# Reinstalls one package regardless of its current state.
~/.config/evangelist/scripts/mason-reinstall.sh force-package lua-language-server
```

### 4. List configured packages
```bash
~/.config/evangelist/scripts/mason-reinstall.sh list
```

## Detailed Usage Examples

### Example 1: A package's install keeps failing
```bash
# Reinstall just the packages mason.log says failed:
~/.config/evangelist/scripts/mason-reinstall.sh reinstall-failed

# Or from inside Neovim:
:MasonReinstall

# Check the log for details:
tail -f ~/.local/share/nvim/mason-reinstall.log
```

### Example 2: Fixing one specific broken installation
```bash
~/.config/evangelist/scripts/mason-reinstall.sh force-package lua-language-server
```

### Example 3: Setting Up a New Machine
```bash
# Install everything from mason-packages.txt that's missing:
~/.config/evangelist/scripts/mason-reinstall.sh install-missing
```

### Example 4: Adding the Script to Your PATH
```bash
# Add to your ~/.zshrc or ~/.bashrc:
export PATH="$HOME/.config/evangelist/scripts:$PATH"

# Then you can use it from anywhere:
mason-reinstall.sh reinstall-failed
```

## Advanced Usage

### Running from Neovim

```lua
-- Reinstall packages that failed to install (per mason.log)
:lua require('user.mason-reinstall').reinstall_from_logfile()

-- Install missing packages from $EVANGELIST/mason-packages.txt
:lua require('user.mason-reinstall').reinstall_from_evnfile()

-- Force reinstall a specific package
:lua require('user.mason-reinstall').force_reinstall_package('shellcheck')
```

Each function accepts an optional callback invoked with a summary table
(`{ total, installed, skipped, failed, missing }`) once every triggered
install has finished:

```lua
require('user.mason-reinstall').reinstall_from_logfile(function(summary)
  vim.notify(vim.inspect(summary))
end)
```

### Neovim Commands

Already defined in `conf/nvim/edge/lua/user/mappings.lua`:

```vim
:MasonReinstall
:MasonInstallMissing
:MasonForcePackage lua-language-server
```

## Package Configuration

### Adding New Packages
Edit `~/.config/evangelist/mason-packages.txt`:

```text
# Language Servers
bash-language-server
lua-language-server
python-lsp-server

# Linters
shellcheck
luacheck
mypy

# Formatters
stylua
prettier
black
```

### Package Name Format
- Use the exact package name from the Mason registry
- One package per line
- Comments start with `#`
- A second whitespace-separated token on a line (an alias, e.g.
  `dockerfile-language-server dockerls`) is accepted and ignored - only
  the first token is used as the package name

## Troubleshooting

### Common Issues and Solutions

1. **"Package not found in registry"**
   ```bash
   # Update Mason registry first
   nvim --headless -c "MasonUpdate" -c "qall"
   ```

2. **Permission errors**
   ```bash
   # Check Neovim data directory permissions
   ls -la ~/.local/share/nvim/
   ```

3. **Network issues during installation**
   ```bash
   # Check connectivity and try again
   curl -I https://github.com
   mason-reinstall.sh force-package <package-name>
   ```

4. **Script not executable**
   ```bash
   chmod +x ~/.config/evangelist/scripts/mason-reinstall.sh
   ```

### Logging and Debugging

View the log file for detailed information:
```bash
# Real-time log monitoring
tail -f ~/.local/share/nvim/mason-reinstall.log

# View recent log entries
tail -n 50 ~/.local/share/nvim/mason-reinstall.log

# Search for errors
grep -i error ~/.local/share/nvim/mason-reinstall.log
```

## Environment Variables

- `EVANGELIST`: Override default evangelist directory path

Example:
```bash
EVANGELIST="/custom/path" mason-reinstall.sh install-missing
```

## Exit Codes

- `0`: Success
- `1`: General error (missing dependencies, file not found, timed out
  waiting for a triggered install to finish)
- `3`: One or more packages failed to install, or weren't found in the
  registry

## Why there's no "force reinstall everything" command

An earlier draft of this tooling had a `force-all` mode that force-reinstalled
every package in `mason-packages.txt` unconditionally. It was dropped: most
of those packages are already installed and working, and forcing a
reinstall of a working package risks breaking it for no benefit. Use
`reinstall-failed` to fix packages that are actually broken, and
`force-package <name>` when you've identified one specific broken
installation - both are scoped to packages that actually need touching.

---

For more information about Mason.nvim, visit: https://github.com/williamboman/mason.nvim
