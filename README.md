# Vim Proliferation

General console and Jupyter settings empowered by Vim!  
It includes bash- and zsh-plugins, contemporary Vim configurations,
and Jupyter Notebook extensions.

***A quick and easy way to set up your every working place!***  
Laptop, remote server, docker container - from now on, they all exploit the same settings\*.  
No need to manually restore you configs every time you buy a new laptop or reinstall the OS.

---
\* the settings shipped by **evangelist**. How similar they are on different machines  
&ensp;will depend on the similarity of installed components among those machines.

<br>


## Contents

- [Installation](#installation)
    - [Evangelist](#evangelist)
    - [Docker](#docker)
- [Features](#features)
- [Troubleshooting](#troubleshooting)
- [References](#references)


## Installation

All settings related to console (including Vim commands that leverage the console)
are fully-supported by Ubuntu and (almost by) macOS. It worth to
mention that the settings themselves are not so platform dependent as
the way they are installed. As the project grows, the settings
and their installation, both, will become more universal and accessible.


### Evangelist

1. **Clone the repository.**
2. **Adjust for yourself** (optional):
    - Go to `nvim` directory, look through the plugins to be installed
      and their configs to be sourced. Comment out those lines you do not
      agree with. Probably, you will have to google first what each plugin
      is about.
    - If the console you are going to work in is `zsh`, check also zsh-plugins
      in `zsh/.zshrc` file.  
</br>
3. **Install minimal list of prerequisites** (The full list depends on the set of plugins you have
chosen in the previous step). For help, run `./evangelist.sh checkhealth`

4. In your console, **run from the project directory**:
    - `./evangelist.sh install <configs>`  
    where `<configs>` is `bash`, `zsh`, or `jupyter`  
</br>
5. **Re-login in the shell.**

Since Vim keeps all changes made to files with its help, one might consider
adding anacron job (or its equivalent on macOS) to remove old undofiles (check `anacron/anacrontab.young`)
or those undofiles which counterparts no longer exist
(check `anacron/anacrontab.alive` and `anacron/purgeVimUndo`).  

For instance, on Linux you can run:

```
sudo cp anacron/anacrontab.young /etc/anacrontab
```


### Docker

One can add vimmer-setup to their docker image (Ubuntu-based) with the command below.
It builds a new image with bash-settings installed on top of the existing environment.
Run this command from the directory where `Dockerfile` resides.

```bash
docker build --build-arg IMG_NAME=<name_of_the_base_image> -t <new_image_name> .
```

By default, `~/.bashrc` is replaced by `bash/bashrc`.  
You can keep some of your settings by wrapping them with delimiting comments:

1. in a running container (then saving it with `docker commit <container> <image>`)

  ```bash
  # >>> RESERVED-CONFS >>>
  your settings
  # <<< RESERVED-CONFS <<<
  ```

2. in the Dockerfile of a "base image" (before the latter is built)

  ```Dockerfile
  RUN some commands \
      && echo "# >>> RESERVED-CONFS >>>" >> ~/.bashrc \
      && ... appending required configs to ~/.bashrc ... \
      && echo "# <<< RESERVED-CONFS <<<" >> ~/.bashrc \
      && other commands
  ```

<br>


## Features

- Efficient navigation in the project directory (commands: `tree`, `d`, `gg`, `G`)
- Interactive command history search (key-bindings: `jjk`, `<M-k>`, `/`)
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
  `leader` is chosen to be `,` in Vim, and `localleader` is `\`.  

---



<details>
<summary><b>Shell</b></summary>

* <details>
  <summary>Bindings</summary>

  | mode | shortcut | &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;assignment |
  |:----:|:--------:|:----------|
  | ins | `jj` | exit insert mode |
  | cmd | `(j|k)` | go to the (next \| previous) matching substring in cmd history <br> _provided no substring,_ go to the (next \| previous) cmd |
  | any | `<M-(j|k)>` | go to the (next \| previous) cmd matching the current buffer from the beginning |
  | any | `<C-q>` | deletes the current buffer, so one can execute another cmd, <br> after which the original one would be restored |
  | cmd | `/` | start interactive fuzzy search over cmds in the history file |

  **NOTE:** the following settings are only supported for X11 based platforms  
  (It means that they will not work or be active on such as macOS or the one with Wayland protocol)
  |      |          |           |
  |:----:|:--------:|:----------|
  | any | `<M-(+|-)>` | (in \| de)crease terminal window transparency a bit |
  </details>

* <details>
  <summary>Aliases and shell functions</summary>

  | alias/function | &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;assignment |
  |:--------------:|:-----------|
  | `tree` | draw a project tree |
  | `v` | open the last file closed (in Vim) |
  | `vv` | start Vim from the list of recently edited files |
  | `d` | show directories visited by user (autocd zsh option) |
  | `(gg|G)` | go through the dir stack in (forward \| backward) direction |
  | `gg n` | go to n-th directory in the list obtained with `d` <br> &emsp;&emsp;&emsp;&emsp;&emsp; (starting from 0) |

  </details>
</details>


<details>
<summary><b>Vim</b></summary>

* <details>
  <summary>General key-bindings and functions</summary>

  | mode | shortcut | &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;assignment |
  |:----:|:--------:|:-----------------------------------------------|
  | normal | `<leader>en` | toggle spell-check |
  | command | Trim | remove all trailing spaces in the file |
  | normal | `<leader>y` | yank current buffer |
  | visual | `<leader>y` | yank selected text |
  | normal | `<leader>t` | paste date and time before the cursor |
  | normal | `<Space><Space>` | turn off highlighting of a searched pattern <br>  or dismiss message in the cmd line below |
  | normal | `<M-(m|M)>` | insert empty line (below \| above) |
  | any | `<F12>` | toggle mouse |
  </details>

* <details>
  <summary>Plugin-related shortcuts</summary>

  |      |          |           |
  |:----:|:--------:|:----------|
  | normal | `<leader>nt` | open NERDTree <br> (helps to navigate through a project tree) |
  | normal | `<leader>nf` | open NERDTree <br> starting from directory in which current file resides |
  | normal | `<leader>md` | open/close markdown preview |
  | normal | `<leader>u` | open undo-tree |
  | normal | `<C-p>` | open CtrlP (file navigation) |
  | normal | `<Space>sy` | show yanks |
  | normal | `<Space>cy` | clear yanks (note: the last one is always kept) |
  | normal | `<M-(n|p)>` | change inserted text with the (next \| previous) yank in the yank buffer |
  <!---
  | ctrlP | `<C-j>`, `<C-k>` | navigation keys |
  | ctrlP | `<C-r>` | enable regex |
  | ctrlP | `<C-f>`, `<C-d>` | switch search mode <br> ('recently opened', 'in the current directory', and etc.) |
  | ctrlP | `<C-c>` | close ctrlP buffer |
  --->
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
| Jupyter | `h(j|k)` | (un- \| \<blank\> )collapse the selected heading cell's section |
| Jupyter | `<C-(j|k)>` | move selected cells (down \| up) |
| Jupyter | `(J|K)` | extend selected cells (below \| above) |

Check the rest settings with `<F1>` or `H` (`<Shift-h>`) while running Jupyter session.
</details>


<details>
<summary><b><b>Tmux</b></b></summary>

| shortcut | &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;assignment |
|:--------:|:-----------|
| `<C-b> + (h|j|k|l)` | go to the window (on the left \| below \| above \| on the right) |
| `<M-S-(h|j|k|l)>` | resize pane moving the border (to the left \| down \| up \| to the right) |
| `<C-b> + (H|J|K|L)` | swap the window that has input focus with <br> the one (on the left \| below \| above \| on the right) |
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
