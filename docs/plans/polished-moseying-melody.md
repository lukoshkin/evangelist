# Add Kitty Terminal as a First-Class Install Target

## Context

The evangelist dotfiles manager handles bash, zsh, git, vim/nvim, tmux, and jupyter
configs but has no dedicated kitty support. The only kitty-related file in the repo is
`conf/kitty/open-actions.conf`, installed as a side-effect of `install::vim_settings`.
The user's `~/.config/kitty/kitty.conf` has a working setup with Catppuccin-Frappe
theme, splits layout, and remote control enabled. We want to:

1. Bring kitty configs into the repo
2. Add full lifecycle management (install/update/uninstall)
3. Add seamless nvim/kitty window navigation via `smart-splits.nvim`
4. Auto-install kitty configs in `bash+`/`zsh+` bundles when the terminal is kitty

## Files to Modify

| File | Action |
|------|--------|
| `conf/kitty/kitty.conf` | **Create** — copy from `~/.config/kitty/kitty.conf`, remove commented-out `include` code block, add smart-splits navigation mappings |
| `conf/nvim/edge/lua/user/core/init.lua` | **Edit** — add `smart-splits.nvim` plugin spec |
| `_impl/install.bash4` | **Edit** — add `install::kitty_settings()`, update `check_arguments` |
| `_impl/control.sh` | **Edit** — add kitty to dispatcher, `bash+`/`zsh+` expansions, uninstall, update |

## Steps

### Step 1: Create `conf/kitty/kitty.conf`

Copy from `~/.config/kitty/kitty.conf` with these changes:
- **Remove** lines 110-113 (the commented-out `include current-theme.conf` block)
- **Add** smart-splits navigation mappings at the end of the keyboard shortcuts section:

```
# Seamless navigation between kitty windows and neovim splits (smart-splits.nvim)
map ctrl+w>ctrl+j neighboring_window down
map ctrl+w>ctrl+k neighboring_window up
map ctrl+w>ctrl+h neighboring_window left
map ctrl+w>ctrl+l neighboring_window right

# When neovim is focused, pass ctrl+w sequences through to neovim
map --when-focus-on var:IS_NVIM ctrl+w>ctrl+j
map --when-focus-on var:IS_NVIM ctrl+w>ctrl+k
map --when-focus-on var:IS_NVIM ctrl+w>ctrl+h
map --when-focus-on var:IS_NVIM ctrl+w>ctrl+l
```

### Step 2: Add `smart-splits.nvim` to neovim plugins

Edit `conf/nvim/edge/lua/user/core/init.lua` — append the plugin spec:

```lua
{
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  build = "./kitty/install-kittens.bash",
  keys = {
    { "<C-w><C-j>", function() require("smart-splits").move_cursor_down() end },
    { "<C-w><C-k>", function() require("smart-splits").move_cursor_up() end },
    { "<C-w><C-h>", function() require("smart-splits").move_cursor_left() end },
    { "<C-w><C-l>", function() require("smart-splits").move_cursor_right() end },
  },
}
```

**Must not be lazy-loaded** (`lazy = false`) — the plugin sets the `IS_NVIM` kitty user
variable at startup, which the `--when-focus-on var:IS_NVIM` kitty mappings depend on.
The `keys` table still defines the navigation keymaps. The `build` hook installs kittens.

### Step 3: Add `install::kitty_settings()` to `_impl/install.bash4`

Insert before `install::vim_settings::without_modifying_shellrc` (after line 253).
Follow the `install::tmux_settings` pattern:

```bash
install::kitty_settings() {
  ECHO Installing Kitty configuration..

  ## Only install if the current terminal is kitty.
  [[ "$TERM" == xterm-kitty ]] || {
    ECHO2 "Not running in kitty terminal. Skipped."
    return 1
  }

  utils::back_up_original_configs kitty \
    d:"$XDG_CONFIG_HOME/kitty"

  mkdir -p "$XDG_CONFIG_HOME/kitty"
  cp conf/kitty/kitty.conf "$XDG_CONFIG_HOME/kitty/"
  cp conf/kitty/open-actions.conf "$XDG_CONFIG_HOME/kitty/"

  ECHO Successfully installed: Kitty configuration.
}
```

Also update `install::check_arguments` (line 10):
```bash
local allowed='bash+/zsh+, bash/zsh, nvim/vim, tmux, jupyter, git, kitty'
```

### Step 4: Remove kitty `open-actions.conf` copy from `install::vim_settings`

Remove lines 162-166 in `_impl/install.bash4` (the `if [[ -f conf/kitty/open-actions.conf ]]`
block inside the Kitty desktop choice). The kitty installer now handles this.

### Step 5: Update `_impl/control.sh`

**Dispatcher** (after line 195 `git) install::git_settings ;;`):
```bash
kitty) install::kitty_settings ;;
```

**bash+/zsh+ expansions** (lines 175-176) — add kitty:
```bash
[[ $* = *bash+* ]] && params=(bash git vim tmux kitty "${params[@]/bash+/}")
[[ $* = *zsh+* ]] && params=(zsh git vim tmux kitty "${params[@]/zsh+/}")
```

**Uninstall** — add after the jupyter block (line 408), before the backup restoration loop:
```bash
if grep -q '^kitty' .update-list; then
  rm -rf "$XDG_CONFIG_HOME/kitty"
fi
```

And in the backup restoration `case` (after the `tmux.conf)` case around line 435):
```bash
kitty)
  cp -R $OBJ "$XDG_CONFIG_HOME"
  ;;
```

**Update** — add a case in the update loop (around line 311, in the `*)`  fallback):
```bash
kitty.conf | open-actions.conf)
  if grep -q '^kitty' .update-list; then
    mkdir -p "$XDG_CONFIG_HOME/kitty"
    cp $OBJ "$XDG_CONFIG_HOME/kitty/"
  fi
  ;;
```

This must go before the existing `*)` fallback case.

### Step 6: Update help text and checkhealth

In `control::help` (line 32), add `kitty` to the listed setups.
In `control::checkhealth`, add:
```bash
write::modulecheck KITTY o:kitty
```

## Verification

1. Run `./evangelist.sh checkhealth` — kitty should appear in the modules list
2. Run `./evangelist.sh install kitty` from a kitty terminal — should back up existing
   config and copy new ones
3. Run `./evangelist.sh install kitty` from a non-kitty terminal — should skip with message
4. Verify `~/.config/kitty/kitty.conf` has the navigation mappings
5. Open neovim, run `:Lazy` — `smart-splits.nvim` should appear and kittens should be installed
6. Test `ctrl+w ctrl+j/k/h/l` navigation between kitty splits and neovim splits
7. Run `./evangelist.sh uninstall` — kitty config should be removed and backup restored
