# Vim Proliferation

General console and Jupyter settings empowered by Vim!  
It includes bash- and zsh-plugins, contemporary Vim configurations,
and Jupyter Notebook extensions.


## Contents

- [Installation](#installation)
    - [Scripts](#scripts)
    - [Location Map](#location-map)
    - [Docker](#docker)
- [Features](#features)
    - [Shell](#shell)
    - [Vim](#vim)
    - [Jupyter](#jupyter)


## Installation

All settings related to console (including Vim commands that leverage the console)
are fully-supported by Ubuntu and partially-supported by macOS. It worth to
mention that the settings themselves are not so platform dependent as
the way they are installed. As the project grows, the both settings
and their installation will become more universal and accessible.


### Scripts
<!---
TODO: Write about anacron and its alternatives

sudo cp -u anacron/anacrontab.young /etc/anacrontab
--->

1. Clone the repository.
2. Adjust for yourself:
    - Go to `nvim` directory, look through the plugins to be installed
      and their configs to be sourced. Comment out those lines you do not
      agree with. Probably, you will have to google first what each plugin
      is about.
    - If the console you are going to work in is `zsh`, check also zsh-plugins
      in `zsh/.zshrc` file.  
</br>
3. Install minimal list of prerequisites (The full list depends on the set of plugins you have
chosen in the previous step). For help run `bash evangelist.sh checkhealth`

4. In a console, run from the project directory:
    - `bash evangelist.sh install <configs>`  
    where `<configs>` is `bash`, `zsh`, or `jupyter`  
</br>
5. Re-login in the shell.


### Location Map

Another way to install is to put each configuration file in the place
where it should be on your machine.

|    | common prefix | destination |
|:--:|:-------------:|:-----------:|
| **bash**| **~/** | .bashrc <br> .inputrc |
| **zsh/zshenv** | **~/** | .zshenv |
| **zsh/<_THE REST_>** | **$ZDOTDIR/** <br> better define it not to clutter **~** | .zshrc <br> agkozakrc <br> extra.zsh <br> conda_autoenv.sh |
| **zsh/agnosterzak.zsh-theme** | **~/** | .zshenv |
| **jupyter** | **$JUPYTER_CONFIG_DIR/** <br> _if defined, otherwise,_ <br> **~/.jupyter/** | custom/custom.js <br> ngconfig/notebook.json |
| **tmux** | **$XDG_CONFIG_HOME/** <br><br> _if defined, otherwise,_ <br><br> **~/** | tmux/tmux.conf <br><br> _or in the latter case,_ <br><br> .tmux.conf |
| **anacron** | **/etc/** | anacrontab |
| **nvim** | **$XDG_CONFIG_HOME/nvim** <br> otherwise, you clutter **~** | init.vim |


### Docker

One can add vimmer-setup to their docker image with the following command.  
It builds a new image with bash-settings installed on top of the existing environment.  
Run this command from the directory where `Dockerfile` resides.

```
docker build --build-arg IMG_NAME=<name_of_the_base_image> -t <new_image_name> .
```


## Features

Before to get into it, get familiar with the imposed notation:  

`C` in shortcuts stands for `Ctrl`. `M` is for `Meta`,
which is `Alt` or `command`, depending on the keyboard layout.  
`<*-*>` is a combination of keys where first ones are modifier of the last one.
`leader` is chosen to be `,` in Vim, and `localleader` is `\`.  


### Shell

| mode | shortcut | assignment |
|:----:|:--------:|:----------|
| ins | `jj` | exit insert mode |
| ins | `<C-u>` | erase character backward |
| ins | `<C-p>` | erase character forward |
| cmd | `j` | go to the next matching substring in cmd history <br> _provided no substring,_ go to the next cmd |
| cmd | `k` | go to the previous matching substring in the history <br> _provided no substring,_ go to the previous cmd  |
| any | `<M-j>` | go to the next cmd matching the current buffer from the beginning |
| any | `<M-k>` | go to the previous cmd matching the current buffer from the beginning |
| any | `<C-q>` | deletes the current buffer, so one can execute another cmd, <br> after which the original one would be restored |
| cmd | `/` | start interactive fuzzy search over cmds in the history file |

**NOTE:** the following settings are only supported for X11 based platforms  
(It means that they will not work or be active on such as macOS or the one with Wayland protocol)
|      |          |           |
|:----:|:--------:|:----------|
| any | `<M-+>` | increase terminal window transparency a bit |
| any | `<M-->` | decrease terminal window transparency a bit |


### Vim

General key-bindings and functions

| mode | shortcut | assignment |
|:----:|:--------:|:-----------|
| normal | `<leader>en` | toggle spell-check |
| command | Trim | remove all trailing spaces in the file |
| normal | `<leader>y` | yank current buffer |
| visual | `<leader>y` | yank selected text |
| normal | `<leader>t` | paste date and time before the cursor |
| normal | `<Space><Space>` | turn off highlighting of a searched pattern <br>  or dismiss message in the cmd line below |
| normal | `<M-m>` | insert empty line below |
| normal | `<M-M>` | insert empty line above |
| any | `<F12>` | toggle mouse |

Plugin-related shortcuts

|      |          |           |
|:----:|:--------:|:----------|
| normal | `<leader>nt` | open NERDTree <br> (helps to navigate through a project tree) |
| normal | `<leader>nf` | open NERDTree <br> starting from directory in which current file resides |
| normal | `<leader>md` | open/close markdown preview |
| normal | `<leader>u` | open undo-tree |
| normal | `<C-p>` | open CtrlP |
| normal | `<Space>sy` | show yanks |
| normal | `<Space>cy` | clear yanks (note: the last one is always kept) |
| normal | `<M-p>` | change to the previous yank in the yank buffer |
| normal | `<M-n>` | change to the next yank in the yank buffer |
| normal | `<Space>yb` | rotate the yank buffer forward |
| normal | `<Space>yb` | rotate the yank buffer backward |
<!---
| ctrlP | `<C-j>`, `<C-k>` | navigation keys |
| ctrlP | `<C-r>` | enable regex |
| ctrlP | `<C-f>`, `<C-d>` | switch search mode <br> ('recently opened', 'in the current directory', and etc.) |
| ctrlP | `<C-c>` | close ctrlP buffer |
--->

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


### Jupyter

| mode | shortcut | assignment |
|:----:|:--------:|:-----------|
| Jupyter | `n` | lift restrictions from selected cells |
| Jupyter | `l` | make selected cells read-only |
| Jupyter | `f` | freeze selected cells |
| Jupyter | `00` | restart the kernel without confirmation |
| Jupyter | `i` | enter Vim mode |
| Vim | `<M-j>` | exit from Vim mode (enables Jupyter mode) |
| Jupyter | `hj` | un-collapse (expand) the selected heading cell's section |
| Jupyter | `hj` | collapse the selected heading cell's section |
| Jupyter | `<C-j>` | move selected cells down |
| Jupyter | `<C-k>` | move selected cells up |
| Jupyter | `J` | extend selected cells below |
| Jupyter | `K` | extend selected cells above |

Check the rest settings with `<F1>` or `H` (`<Shift-h>`) while running Jupyter session.
