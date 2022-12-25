# Vim Proliferation

_"I came up with **evangelist** and am developing it so I could configure everything less when I am dead."_

---

#### About the project

A wide set of configurations for Vim, Bash/Zsh, Tmux, and Jupyter.  
Deploy them on a laptop, remote server, or in a docker container.  
Revert to your original settings with the `uninstall` command.

[More information on the first wiki page!](https://github.com/lukoshkin/evangelist/wiki/Philosophy)


## Contents

- [Installation](#installation)
    - [Evangelist](#evangelist)
    - [Docker](#docker)
- [Features](#features)
- [Troubleshooting](#troubleshooting)
- [References](#references)
- [TODO list](#todo-list)


## Installation

All settings made to the console (including Vim commands that rely on the console)
are fully supported by Ubuntu and (almost completely) by macOS. It is worth to
mention that the settings themselves are not as platform dependent as
the way of their installation. As the project grows, the settings
and the setup script will become more universal and cross-platform.


### Evangelist

1. **Clone the repository.**  
    For example:
    ```bash
    git clone https://github.com/lukoshkin/evangelist.git ~/.config/evangelist
    cd ~/.config/evangelist
    ```

2. **Install at least minimal list of prerequisites**  
   Run `./evangelist.sh checkhealth` for help.

3. In your console, **run from the project directory**:
    - `./evangelist.sh install <configs>`  
    where `<configs>` can be `bash`, `zsh`, `vim`, `tmux`, `jupyter`  
    (you can specify more than one argument)

    - To ensure the command history transfer, you may run instead:  
    `export HISTFILE; ./evangelist.sh install <shell> <other args>`  
    where `<shell>` is `bash` or `zsh`

4. **Re-login in the shell.**

5. **Adjust for yourself** (optional).  
    Use `vimrc`, `zshrc` or `bashrc` commands to customize settings.

<br>

Since Vim keeps all changes made to files with it, on Linux, one might consider
adding anacron job (or its equivalent on macOS) by running `anacron/anacron.sh` script.

* to remove old undofiles  
`./anacron.sh old @monthly`

* or those undofiles which counterparts no longer exist  
`./anacron.sh dead 30`

Note, if you are a user of a different OS, you will have to set up 'auto-purge' of the undodir manually.  
To get more information about what arguments `anacron.sh` takes, type `./anacron.sh`.

Also, check the `develop` branch for recent updates. If there are any,
you may want to incorporate them by typing `git checkout develop` before
going to the step 2.


### Docker

One can add vimmer-setup to their docker image (Ubuntu-based) with the command below.
It builds a new image with bash-settings installed on top of the existing environment.
Run this command from the directory where `Dockerfile` resides.

```bash
docker build --build-arg IMG_NAME=<name_of_the_base_image> -t <new_image_name> .
```

If installing zsh-settings with the **evangelist** inside a docker container,
run the latter with `-e TERM=xterm-256color` option. Otherwise, you will end up
with broken colors during the process of both the installation and exploitation.

  ```
  docker run --name <container_name> -e TERM=xterm-256color -ti <name_you_gave_in_build_command>
  ```

<br>


## Features

- Light implementation of [conda-autoenv](https://github.com/sharonzhou/conda-autoenv)
  which supports both bash and zsh
- Efficient navigation in the project directory (commands: `tree`, `d`, `gg`, `G`)
- Interactive command history search (key-bindings: `jjk`, `<M-kk>`, `/`)
- Jupyter empowered by Vim and basic set of notebook extensions
- Minimal configuration for Tmux and several configuration levels for Vim/Neovim

<br>
<br>

Before to go into details, let's get familiar with the imposed notation:  

---

  `C` in shortcuts stands for `Ctrl`.  
  `M` is for `Meta`, which is `Alt` or `command`, depending on the keyboard layout.  
  `<*-*>` is a combination of keys where first ones are modifier of the last one.  
  `(a|b)` means the use of either a or b key in the given combination.  
  By default, `Leader` is mapped to `\` in Vim, `LocalLeader` to `<Space>`.  
  But you can change both values in your `custom/custom.vim`.

---


Patch 1.4.5 (!)

<details>
<summary><b>Shell</b></summary>

* <details>
  <summary>Bindings</summary>
  modes: ins - insert, cmd - command, tbc - tab completion

  | mode | shortcut | &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;assignment |
  |:----:|:--------:|:----------|
  | ins | `jj` | Exit insert mode |
  | cmd | `(j\|k)` | Go to the (next \| Previous) matching substring in cmd history <br> _provided no substring,_ go to the (next \| previous) cmd |
  | any | `<M-(j\|k)>` | Go to the (next \| previous) cmd matching the current buffer from <br> the beginning (Note: one more `<j/k>` press to exit from ins mode) |
  | any | `<C-q>` | Deletes the current buffer, so one can execute another cmd, <br> after which the original one would be restored |
  | cmd | `/` | Start interactive fuzzy search over cmds in the history file |
  | tbc | `?` | Start isearch (# of completion options can be narrowed <br> by typing more chars) |
  | any | `<C-a>` | Change the prefix of the current command |

  **NOTE:** the following settings are only supported by X11 based platforms  
  (It means that they will not work or be active on such as macOS or the one with Wayland protocol)
  |    |    |   |
  |:--:|:--:|:--|
  | any | `<M-(+\|-)>` | (in \| de)crease terminal window transparency a bit |
  </details>

* <details>
  <summary>Aliases and shell functions</summary>

  | alias/function | &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;assignment |
  |:--------------:|:-----------|
  | `mkenv [env]` | Remember the environment used in a folder to <br> [de]activate the former when [leaving]/entering the latter <br> _(supports only conda environments)_ |
  | `md` | Create a directory (or nested folders) and cd there |
  | `tree` | Draw a project tree (files and directories); <br> if not installed `dtree` is called instead <br> (a "safe" wrapper around Unix `tree`) |
  | `dtree` | Draw a project tree (folders only) |
  | `v` | Open the last file closed (in Vim) |
  | `vip` | Make the "vim-ipython" split in tmux <br> (available only if tmux settings are installed; former configuration) |
  | `vrmswp [name]` | Delete swap file by name or part of its name |
  | `d` | Show directories visited by user (autocd zsh option) |
  | `(gg\|G)` | Go through the dir stack in (forward \| backward) direction |
  | `gg <n>` | Go to n-th directory in the list obtained with `d` <br> &emsp;&emsp;&emsp;&emsp;&emsp; (starting from 0) |
  | `gg -<n>` | Remove n-th directory from the dir stack |
  | `swap` | Swap names of two targets |
  | `rexgrep <str>` | is equivalent to `grep -rIn --exclude-dir='.?*' <str>`, (exclude <br> hidden directories, binary files from recursive search; add numbering) |
  | `(bash\|zsh\|vim)rc`\* | Edit user-defined settings for the specified target |
  | `_(bash\|zsh\|vim)rc` | Open main config file for the specified target |
  | `math` | Calculate simple expressions <br> (the result is stored in `_ANS` and can be reused) |
  | `evn\|evangelist` | Alias for evangelist.sh executable script |

  \* Note, the priority is given to custom settings. Also, they will not be overwritten by
  updates or new installations.

  </details>
</details>


<details>
<summary><b>Vim</b></summary>

modes: n - normal, v - visual, t - terminal, c - command mapping  
different setups: old settings (minimal), extended settings, Neovim-Lua (edge, v0.7)

* <details>
  <summary>General key-bindings and functions (common)</summary>

  | mode | shortcut | &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;assignment |
  |:----:|:--------:|:-----------------------------------------------|
  | n | `<Leader>en` | Toggle spell-check |
  | n | `<Leader>y` | Yank current buffer |
  | v | `<Leader>y` | Yank selected text |
  | n | `<Leader>ts` | Paste date and time before the cursor |
  | n | `<Leader>nu` | Toggle line numbering and sign column |
  | n | `<Space>b<Space>` | Split line at the next space after the cursor position |
  | v | `<Space>b<Space>` | Split the entire line at spaces |
  | n | `<Space>bb` | Split line at the next char you previously searched with `f` |
  | v | `<Space>bb` | Split the entire line at a separator you searched with `/` |
  | n | `<Space><Space>` | Clear a search pattern highlighting, <br> dismiss a message in the cmd line below or in floating wins |
  | n | `<Leader>x` | Open file under the cursor with xdg-open |
  | any | `<C-s>` | Save changes to a file |
  | n+v | `<C-(j\|k)>` | Move lines (down\|up) |
  | n | `<M-(h\|j\|k\|l)>` | Insert an empty line or space in the direction <br> which a movement key specifies |
  | n | `<S-M-(h\|j\|k\|l)>` |  Same, but the cursor remains on the current char |
  | c | `Trim` | Remove all trailing spaces in the whole file or for visual selection |
  | c | `Rmswp` | Delete the swap file corresponding to the current buffer |
  | v | `//` | Search for selected text <br> (doesn't work in `VISUAL LINE` mode) |
  | any | `<M-m>` | Toggle mouse |
  | v | `p` | Paste the last yanked text in place of selected one |
  | n | `<A-r>` | Repeat the last colon command used |
  | n | `<A-(n\|N)>` | Do not center window when searching |
  | n | `<Space>t` | Open the current buffer in a new tab.<br> One can close the tab later with `ZZ` or `ZQ` |

  </details>

* <details>
  <summary>Plugins (w/o dependencies) and related mappings</summary>

  **Available at all levels**

  |    |    |   |
  |:--:|:--:|:--|
  | n | `<Leader>nt` | Open tree explorer <br> (helps to navigate through a project tree) |
  | n | `<Leader>nf` | Open tree explorer <br> starting from a directory of the current file |
  | n | `<Leader>u` | Open undo-tree |

  |   |   |
  |:--|:--|
  | [nord.nvim](https://github.com/shaunsingh/nord.nvim) | Change the default color scheme to nord |
  | [trailing-whitespace](https://github.com/lukoshkin/trailing-whitespace) | Trailing whitespace highlighting |
  | [vim-eunuch](https://github.com/tpope/vim-eunuch) | Adds useful commands like `:SudoWrite`, `:Rename`, and etc. |
  | [vim-heritage](https://github.com/jessarcher/vim-heritage) | Create a parent directory (if need be) when saving a file |
  | [vim-lastplace](https://github.com/farmergreg/vim-lastplace) | Open file at the last edit position |
  | [vim-mundo](https://github.com/simnalamburt/vim-mundo) | Visualize Vim undo tree |
  | [vim-pasta](https://github.com/sickill/vim-pasta) | Auto-indent on pasting |
  | [vim-repeat](https://github.com/tpope/vim-repeat) | Repeat with `.` complex commands (e.g., containing `<Plug>`) |
  | [vim-sleuth](https://github.com/tpope/vim-sleuth) | Automatically adjust `shiftwidth` & `expandtab` |
  | [vim-surround](https://github.com/tpope/vim-surround) | Surround with quotation marks, tags, and more. Remove them or substitute |
  | [vim-commentary](https://github.com/tpope/vim-commentary) | Commenting and uncommenting lines |

  **With Neovim-Lua setup and entended settings**

  |   |   |
  |:--|:--|
  | [vimspector](https://github.com/puremourning/vimspector) | Code debugger |
  | [vimtex](https://github.com/lervag/vimtex) | Mappings, highlighting, compilation for LaTex files |
  | [markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim) | Preview markdown in the user's browser |
  | [vim-slime](https://github.com/jpalardy/vim-slime.git) | Send code on the left to a split on the right and execute it if possible |
  | [vim-ipython-cell](https://github.com/hanschen/vim-ipython-cell.git) | Build cell layout for Python code with a delimiter |

  |    |    |   |
  |:--:|:--:|:--|
  | n | `<Leader>md` | Open/close markdown preview |
  | n | `<C-p>` | Open CtrlP fuzzy finder |

  Vimspector

  |    |    |   |
  |:--:|:--:|:--|
  | n | `<Leader>dc` | Switch to the debug mode <br> or continue running |
  | n | `<Leader>dr` | Terminate debug session and switch to regular editing |
  | <br>n | <br>`<Leader>ds` | Stop the debugger <br> (You can not continue from where you have stopped. <br> Unlike reset, all windows remain оpen) |
  | n | `<Leader>dd` | Pause the debugger |
  | n | `<Leader>d0` | Restart the debugger |
  | n | `<Space>=` | Step into |
  | n | `<Space>+` | Step over |
  | n | `<Space>-` | Step out |
  | n | `<Space>.` | Toggle breakpoint |
  | n | `<Space>,` | Add a conditional breakpoint |
  | n | `<Space>:` | Add a function breakpoint |
  | n | `<Space>db` | Toggle section with breakpoints list |
  | n | `<Space>dd` | Go to the section with source code |
  | n | `<Space>dv` | Go to the variables section |
  | n | `<Space>dw` | Go to the watches section |
  | n | `<Space>do` | Go to the section with output |
  | n | `<Space>dt` | Go to the terminal <br> if Vimspector has opened it |
  | n | `<Space>ds` | Go to the 'stack trace' section |

  **With extended settings**

  |   |   |
  |:--|:--|
  | [vim-floaterm](https://github.com/voldikss/vim-floaterm) | Terminal in a floating window |
  | [coc.nvim](https://github.com/neoclide/coc.nvim) | Completion engine, syntax parsing, and more |
  | [ctrlp.vim](https://github.com/ctrlpvim/ctrlp.vim.git) | fuzzy search among MRU files, current folder content |
  | [eregex.vim](https://github.com/othree/eregex.vim.git) | Toggle between Vim and Perl regular expressions (`<Leader>re` nmap) |

  **With Neovim-Lua setup**

  |   |   |
  |:--|:--|
  | [LuaSnip](https://github.com/L3MON4D3/LuaSnip) | Code snippets |
  | [auenv.nvim](https://github.com/lukoshkin/auenv.nvim) | Automatically switch between conda envs |
  | [bterm.nvim](https://github.com/lukoshkin/bterm.nvim) | Simple terminal call |
  | [bufferline.nvim](https://github.com/akinsho/bufferline.nvim) | Display tabs with buffers at the top |
  | [dashboard-nvim](https://github.com/glepnir/dashboard-nvim) | Starting page on open |
  | [fidget.nvim](https://github.com/j-hui/fidget.nvim) | Widget displaying the loading progress of Neovim LSP |
  | [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Mark changes to the working tree in the sign column |
  | [vim-easy-align](https://github.com/junegunn/vim-easy-align) | Align block of text |
  | [lsp_signature.nvim](https://github.com/ray-x/lsp_signature.nvim) | Display signature help when modifying function arguments |
  | [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | Better status line |
  | [null-ls.nvim](https://github.com/jose-elias-alvarez/null-ls.nvim) | Embed non-LSP sources in Neovim |
  | [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | Text/code-completion engine |
  | [nvim-code-action-menu](https://github.com/weilbith/nvim-code-action-menu) | GUI for code action menu |
  | [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | Configs for Neovim LSP client |
  | [nvim-neoclip.lua](https://github.com/AckslD/nvim-neoclip.lua) | Pick one of previous yanks for pasting |
  | [nvim-notify](https://github.com/rcarriga/nvim-notify) | Display errors, warnings, hints in floating windows |
  | [nvim-tree.lua](https://github.com/kyazdani42/nvim-tree.lua) | File explorer |
  | [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | [Tree-sitter](https://github.com/tree-sitter/tree-sitter) in Neovim |
  | [project.nvim](https://github.com/ahmedkhalf/project.nvim) | Automatically change CWD to the root of the project |
  | [quick-scope](https://github.com/unblevable/quick-scope) | Highlight word anchors within the line to do t/f-movement |
  | [slime-wrapper.nvim](https://github.com/lukoshkin/slime-wrapper.nvim) | Mimic JupyterLab |
  | [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Advanced file search with preview |
  | [vim-doge](https://github.com/kkoomen/vim-doge) | Generate documentation template for a function/class |
  | [vim-sayonara](https://github.com/mhinz/vim-sayonara) | Wipe out a buffer, don't close the window |

  Jumps

  |    |    |   |
  |:--:|:--:|:--|
  | n | `[g` | Jump to the previous sign of gitsigns |
  | n | `]g` | Jump to the next sign of gitsigns |
  | n | `[d` | Jump to the previous diagnostic |
  | n | `]d` | Jump to the next diagnostic |
  | n | `[e` | Jump to the previous error (higher diagnostic severity lvl) |
  | n | `]e` | Jump to the next error (higher diagnostic severity lvl) |
  | n | `[b` | Jump to the previous buffer |
  | n | `]b` | Jump to the next buffer |

  Telescope

  |    |    |   |
  |:--:|:--:|:--|
  | n | `<Leader>b` | Open available buffers in Telescope |
  | n | `<Leader>fo` | Open most recently used files in Telescope |
  | n | `<Leader>fp` | Open projects in Telescope |
  | n | `<Leader>fy` | Open previous yanks in Telescope |
  | n | `<Leader>fe` | Open files in Telescope (exact search) |
  | n | `<Leader>ff` | Open files in Telescope (fuzzy search) |
  | n | `<Leader>fa` | Same but abolish all external ignore patterns |
  | n | `<Leader>fg` | Find string with grep options in Telescope |
  | n | `gr` | Open LSP references of the symbol under the cursor in Telescope |
  | n | `<Leader>fh` | Find a help tag with Telescope |
  | n | `<Leader>fk` | Find a key mapping with Telescope |

  LSP keymaps (most of LSP mappings are valid for extended settings as well)

  |    |    |   |
  |:--:|:--:|:--|
  | n | `gd` | Go to definition |
  | n | `gD` | Go to declaration |
  | n | `gs` | Show signature help |
  | n | `ge` | Show diagnostic message |
  | n | `<Leader>i` | Go to implementation |
  | n | `<Leader>td` | Go to type definition |
  | n | `K` | Display hover information about the symbol under the cursor |
  | n | `<Leader>rn` | Rename symbol under the cursor |
  | n | `<Space>q` | Open diagnostics in the location list |
  | n | `<Leader>fs` | Open documents symbols in the location list |
  | n+v | `<Leader>ca` | Open code action menu |

  Completions

  |    |    |   |
  |:--:|:--:|:--|
  | i | `<C-e>` | Close the completion menu \& restore the current line to its original state |
  | i | `<C-y>` | Close the completion menu \& complete to the currently selected option |
  | i | `<Tab>` | Jump to the next position in a snippet |

  Some mappings of evangelist's offspring projects

  |    |    |   |
  |:--:|:--:|:--|
  | n | `<Space>ip` | Start IPython session in a split on the right |
  | n | `<Leader>ss` | Select an interpreter to start a Vim-SLIME session |
  | n+t | `<M-t>` | Toggle bottom terminal |
  | t | `<C-t>` | Flip terminal from horizontal to vertical orientation |

  Miscellanea

  |    |    |   |
  |:--:|:--:|:--|
  | n+v | `<Leader>hr` | Undo change made to a hunk (in git diff) under the cursor |
  | <br>n+v | <br>`ga` | Align a block of text <br> One specifies the range by a movement or selection. <br> `<Enter>` switches the alignment mode |
  | n | `<LocalLeader>dg` | Generate documentation for a function or a class |
  | c | `:Insert <cmd>` | Paste the cmd output to the current buffer |
  | c | `:Print <lua_table>` | Print lua table in the cmdline window |
  | <br>n | <br>`<C-(Up\|Down\|Left\|Right)>` | Resize window <br> vertically (Up+/Down-) <br> or horizontally (Left-/Right+) |

  </details>
</details>


<details>
<summary><b>Jupyter</b></summary>

| mode | shortcut | &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;assignment |
|:----:|:--------:|:-----------|
| Jupyter | `n` | lift restrictions from selected cells |
| Jupyter | `l` | make selected cells read-only |
| Jupyter | `f` | freeze selected cells |
| Jupyter | `00` | restart the kernel without confirmation |
| Jupyter | `i` | enter Vim mode |
| Vim | `<M-j>` | exit from Vim mode (enables Jupyter mode) |
| Jupyter | `h(j\|k)` | (un- \| \<blank\> )collapse the selected heading cell's section |
| Jupyter | `<C-(j\|k)>` | move selected cells (down \| up) |
| Jupyter | `(J\|K)` | extend selected cells (below \| above) |

Check the rest settings with `<F1>` or `H` (`<Shift-h>`) while running Jupyter session.
</details>


<details>
<summary><b><b>Tmux</b></b></summary>

| shortcut | &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;assignment |
|:--------:|:-----------|
| `<C-b> + (h\|j\|k\|l)` | go to the window (on the left \| below \| above \| on the right) |
| `<M-S-(h\|j\|k\|l)>` | resize pane moving the border (to the left \| down \| up \| to the right) |
| `<C-b> + (H\|J\|K\|L)` | swap the window that has input focus with <br> the one (on the left \| below \| above \| on the right) |
| `<C-b>Q` | close vim buffers (saving them first if modified) and terminate tmux session |
| `<C-b>y` | toggle synchronous input in all panes |
| `<C-b>m` | toggle mouse support |

</details>

---

The described features correspond to zsh + Neovim setup. If you work in bash,
and your editor is Vim, then some of bindings may not be available. Moreover,
for macOS users, their default settings with `command` take precedence over
the ones defined by ***evangelist***.

<br>


## Troubleshooting

* **IDE**

  If for some reason you want to use Vim in the IDE, you will have to define
  XDG base directory specification in `.zshrc` (since some IDEs don't read `~/.zshenv`).

* **Vim vs Neovim**

  There is no much difference between them if comparing with latest Vim version.
  But some plugins may produce errors in its old versions. For example,
  in Vim 7.4 `enter` for opening a file or expanding a folder does not work.
  Instead, you should use `o` key.

<!--
* **Command history in docker container**

  If you log out, and your container is still running, you may sometime
  encounter a problem that your command history is deleted every time you exit.
  In this case, it can be resolved with `docker stop` + `docker start`:

  ```
  docker stop <your_container_name>
  docker start <your_container_name>
  docker exec -ti <your_container_name> <shell_name>
  ```
-->

* **Ctrl-c**

  Currently, pressing `<C-c>` during evangelist's execution kills the process group.
  Since there is no clean-up procedure that would revert actions of unfinished command,
  you may try to call the latter again or go from scratch with `uninstall`.


* **`_ignorecommon` in zsh**

  If some of your commands are not saved during zsh-session,
  and you find this behavior undesirable, then you can remove
  these commands from `_ignorecommon` string in your `$ZDOTDIR/extra.zsh`

* **Cannot enter insert mode**

  If you get stuck in vi-cmd mode in the shell, what happens infrequently,
  you can handle this by hitting `Enter`, `I` (`<S-i>`), `a`, or any
  other key combination that may be considered as an alternative to `i`.

* **Meta key on macOS**

  To use shortcuts involving `Meta` key on macOS, you need to check out
  the Meta key option in iTerm2 preferences. Also, you may need to make
  sure that there are no overlapping Meta key bindings with the ones
  the system uses. In Neovim, you can try alternative bindings
  involding command key (`<D-...>` instead of `<A-...>` and `<M-...>`).

* **Tmux outputs errors on startup**

  If this is the case, one needs to comment out the lines/blocks
  (they marked in `tmux.conf`) that use the syntax of newer Tmux versions,
  than the installed one. This will be fixed in the next patches.

* **Enforce installation in a new folder**

  Because of the current implementation, you cannot simply change the
  installation path by running `./evangelist.sh install <shell>`
  under a new folder. You need to first unset the variable with
  the installation path to an active evangelist instance:

  `unset EVANGELIST; ./evangelist.sh install <args>`

<br>


## References

This work is based primarily on leveraging the following projects and resources.

<table>
  <tr>
    <td> - <a href="https://github.com/junegunn/vim-plug"> vim-plug </a> </td>
    <td> a minimalist Vim plugin manager </td>
  </tr>

  <tr>
    <td> - <a href="https://github.com/agkozak/zcomet"> zcomet </a> </td>
    <td> Zsh plugin manager </td>
  </tr>

  <tr>
    <td> - <a href="https://github.com/lambdalisue/jupyter-vim-binding"> jupyter-vim-binding </a> </td>
    <td> Vim extension for Jupyter Notebook </td>
  </tr>

  <tr>
    <td> - <a href="https://github.com/LunarVim/LunarVim.git"> LunarVim </a> </td>
    <td> An IDE layer for Neovim </td>
  </tr>

  <tr>
    <td> - <a href="https://github.com/jessarcher/dotfiles"> dotfiles1 </a>
    <br> - <a href="https://github.com/alpha2phi/dotfiles"> dotfiles2 </a>
    <br> - <a href="https://github.com/folke/dot"> dotfiles3 </a>
    </td>
    <td> <br> custom settings I found on Git </td>
  </tr>
</table>

<br>


## TODO list

 - [x] Write Dockerfile
 - [x] Add `install`, `update`, `reinstall`, `uninstall` control functions
 - [x] Add `EVANGELIST` environment variable
 - [x] Write bash/zsh completions
 - [x] Write Wiki evangelist
 ---

 - [x] Switch from `init.vim` to `init.lua` (for Neovim)
 - [x] Switch from CoC to configs with Native LSP (for Neovim)
 - [x] Test LunarVim / SpaceVim
 ---

 - [ ] Tidy up the repository
