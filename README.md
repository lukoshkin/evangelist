# Vim Proliferation

General settings of console and Jupyter that are empowered by Vim!  
The package includes bash- and zsh-plugins, up-to-date Vim configurations,
and Jupyter Notebook extensions.

***A quick and easy way to configure all your workstations!***  
Your laptop, the remote server you use, a docker container -
from now on, a couple of commands and they all have the same settings<sup>\*</sup>.
No need to manually restore your configs each time you buy a new laptop or reinstall the OS.

Give it a shot! And if you don't like `evangelist`, you can always revert to
your previous settings with its uninstall command.

---
<sup>\*</sup> the settings shipped by **evangelist**. Their similarity on different machines  
&ensp;will depend on the similarity of installed components among those machines.

<br>


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

2. **Install minimal list of prerequisites** (The full list depends on the set of plugins you have
chosen in the previous step). For help, run `./evangelist.sh checkhealth`

3. In your console, **run from the project directory**:
    - `./evangelist.sh install <configs>`  
    where `<configs>` can be `bash`, `zsh`, `vim`, `tmux`, `jupyter`  
    (you can specify more than one argument)

    - To ensure the command history transfer, you may run instead:  
    `export HISTFILE; ./evangelist.sh install <shell> <other args>`  
    where `<shell>` is `bash` or `zsh`

4. **Re-login in the shell.**

5. **Confirm the installation of zsh-plugins** (if selected zsh in step 4).

6. **Adjust for yourself** (optional):
    - Go to `nvim` directory, look through the plugins to be installed
      and their configs to be sourced. Comment out those lines you do not
      agree with. Probably, you will have to google first what each plugin
      is about.
    - If the console you are going to work in is `zsh`, check also zsh-plugins
      in `zsh/.zshrc` file.

<br>

Since Vim keeps all changes made to files with its help, on Linux, one might consider
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
- Minimal configurations for Vim and Tmux

<br>
<br>

Before to get into it, let's get familiar with the imposed notation:  

---

  `C` in shortcuts stands for `Ctrl`.  
  `M` is for `Meta`, which is `Alt` or `command`, depending on the keyboard layout.  
  `<*-*>` is a combination of keys where first ones are modifier of the last one.  
  `(a|b)` means the use of either a or b key in the given combination.  
  By default, `leader` is mapped to `\` in Vim, as well as `localleader`.  
  But you can change both values in your `custom/custom.vim`.

---


Patch 1.2.11 (!)

<details>
<summary><b>Shell</b></summary>

* <details>
  <summary>Bindings</summary>

  | mode | shortcut | &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;assignment |
  |:----:|:--------:|:----------|
  | ins | `jj` | exit insert mode |
  | cmd | `(j\|k)` | go to the (next \| previous) matching substring in cmd history <br> _provided no substring,_ go to the (next \| previous) cmd |
  | any <br>  | `<M-(j\|k)>` | go to the (next \| previous) cmd matching the current buffer from <br> the beginning (Note: one more `<j/k>` press to exit from ins mode) |
  | any | `<C-q>` | deletes the current buffer, so one can execute another cmd, <br> after which the original one would be restored |
  | cmd | `/` | start interactive fuzzy search over cmds in the history file |

  **NOTE:** the following settings are only supported for X11 based platforms  
  (It means that they will not work or be active on such as macOS or the one with Wayland protocol)
  |      |          |           |
  |:----:|:--------:|:----------|
  | any | `<M-(+\|-)>` | (in \| de)crease terminal window transparency a bit |
  </details>

* <details>
  <summary>Aliases and shell functions</summary>

  | alias/function | &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;assignment |
  |:--------------:|:-----------|
  | `mkenv [env]` | remember the environment used in a folder to <br> [de]activate the former when [leaving]/entering the latter <br> ***(supports only conda environments)*** |
  | `md` | create a directory (or nested folders) and cd there |
  | `tree` | draw a project tree (files and directories); <br> if not installed `dtree` is called instead <br> (a "safe" wrapper around Unix `tree`) |
  | `dtree` | draw a project tree (folders only) |
  | `v` | open the last file closed (in Vim) |
  | `vv` | start Vim from the list of recently edited files |
  | `vip` | initiate the "vim-ipython" split in tmux <br> (available only if tmux settings are installed) |
  | `vrmswp [name]` | delete swap file by name or part of its name |
  | `d` | show directories visited by user (autocd zsh option) |
  | `(gg\|G)` | go through the dir stack in (forward \| backward) direction |
  | `gg n` | go to n-th directory in the list obtained with `d` <br> &emsp;&emsp;&emsp;&emsp;&emsp; (starting from 0) |
  | `gg -n` | remove n-th directory from the dir stack |
  | `swap` | swap names of two targets |
  | `rexgrep <str>` | is equivalent to `grep -r --exclude-dir='.?*' <str>`, <br> which excludes hidden directories from recursive search |
  | `(bash\|zsh\|vim)rc`\* | edit user-defined settings for the specified target |
  | `_(bash\|zsh\|vim)rc` | open main config file for the specified target |
  | `evn\|evangelist` | alias for evangelist.sh executable script |

  \* Note, the priority is given to custom settings. Also, they will not be overwritten by
  updates or new installations.

  </details>
</details>


<details>
<summary><b>Vim</b></summary>

* <details>
  <summary>General key-bindings and functions</summary>

  | mode | shortcut | &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;assignment |
  |:----:|:--------:|:-----------------------------------------------|
  | normal | `<leader>en` | toggle spell-check |
  | normal | `<leader>y` | yank current buffer |
  | visual | `<leader>y` | yank selected text |
  | normal | `<leader>t` | paste date and time before the cursor |
  | normal | `<leader>nu` | toggle line numbering |
  | normal | `<Space>b<Space>` | split line at the next space after the cursor position |
  | visual | `<Space>b<Space>` | split the entire line at spaces |
  | normal | `<Space>bb` | split line at the next char you previously searched with `f` |
  | visual | `<Space>bb` | split the entire line at a separator you searched with `/` |
  | normal | `<Space><Space>` | turn off highlighting of a searched pattern <br>  or dismiss a message in the cmd line below |
  | normal | `<M-(h\|j\|k\|l)>` | insert an empty line or space in the direction <br> which a movement key specifies |
  | command | Trim | remove all trailing spaces in the file |
  | command | Rmswp | delete the corresponding to open buffer swap file |
  | visual | `//` | search for selected text <br> (doesn't work in `VISUAL LINE` mode) |
  | any | `<A-m>` | toggle mouse |
  </details>

* <details>
  <summary>Plugin-related shortcuts</summary>

  |      |          |           |
  |:----:|:--------:|:----------|
  | normal | `<leader>nt` | open NERDTree <br> (helps to navigate through a project tree) |
  | normal | `<leader>nf` | open NERDTree <br> starting from a directory in which current file resides |
  | normal | `<leader>md` | open/close markdown preview |
  | normal | `<leader>u` | open undo-tree |
  | normal | `<C-p>` | open CtrlP (file navigation) |
  <!--
  | ctrlP | `<C-j>`, `<C-k>` | navigation keys |
  | ctrlP | `<C-r>` | enable regex |
  | ctrlP | `<C-f>`, `<C-d>` | switch search mode <br> ('recently opened', 'in the current directory', and etc.) |
  | ctrlP | `<C-c>` | close ctrlP buffer |
  -->
  </details>

* <details>
  <summary>Extra functionality</summary>

  The functionality below is available after uncommenting respective lines in `init.vim` file

  |      |          |           |
  |:----:|:--------:|:----------|
  | normal | `<localleader>ll` | toggle compilation of a tex file in continuous mode |
  | normal | `<localleader>lc` | clean auxiliary files |
  | normal | `<localleader>lC` | clean all auxiliaries including generated pdf |
  | normal | `<leader>err` | check compilation errors (listed in a location list) |
  | normal | `[g` | go to the previous error in the location list |
  | normal | `]g` | go to the next error in the location list |
  | normal | `gd` | go to definition or declaration |
  | normal | `gk` | open documentation of function, class or etc. |
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

  If you are not going to use Vim, and prefer IDE apps instead. You need to
  expand the export of `ZPLUG_HOME` in `.zshrc` file (assuming your login shell is zsh)
  to be able to use the configured terminal emulator in your IDE. If for some reason
  you want to use Vim in the IDE, you will have to define XDG base directory specification
  in `.zshrc` as well (since some IDEs don't read `~/.zshenv`).

* **Vim vs Neovim**

  There is no much difference between them if comparing with latest Vim version.
  But some plugins may produce errors in its old versions. For example,
  in Vim 7.4 `enter` for opening a file or expanding a folder does not work.
  Instead, you should use `o` key.

<!--
* **Command history in docker container**

  If you log out, and your container is still running, you may sometime
  encounter the problem that your command history is deleted every time you exit.
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

This work is based primarily on leveraging the following projects.

<table>
  <tr>
    <td> - <a href="https://github.com/junegunn/vim-plug"> vim-plug </a> </td>
    <td> a minimalist Vim plugin manager </td>
  </tr>

  <tr>
    <td> - <a href="https://github.com/zplug/zplug"> zplug </a> </td>
    <td> zsh plugin Manager </td>
  </tr>

  <tr>
    <td> - <a href="https://github.com/lambdalisue/jupyter-vim-binding"> jupyter-vim-binding </a> </td>
    <td> Vim extension for Jupyter Notebook </td>
  </tr>
</table>

<br>


## TODO list

 - [x] Write Dockerfile
 - [x] Add `install`, `update`, `reinstall`, `uninstall` control functions
 - [x] Add `EVANGELIST` environment variable
 - [x] Write bash/zsh completions
 - [ ] Write Wiki evangelist
 - [ ] Add [Vim-tutor](https://github.com/lukoshkin/vim-tutor) to evangelist as a submodule
