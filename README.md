# Vimmer Set-up 

General settings for zsh, tmux, and vim!

The goal of this project is:  
1. to develop some standard settings when working in the console  
2. to help novices, rookies, newcomers, or whoever they could be become an "expert"
in a "short time"

Anyone who support this can collaborate!

**ToDo**:
1. describe features
2. list all dependencies (like clangd for YCM, nodejs and etc.)
3. "upgrade" from `dummy-install.sh` to '_smarter_'-`install.sh` (not silly, at least)
4. add to more set-ups: _zsh-vimmer_ and _fully-fledged zsh-vimmer_

## Installation

1. Clone the repository.
2. Go to `nvim` directory, look through the plugins to be installed
and their configs to be sourced. Comment out those lines you do not
agree with. Probably, you will have to google first what each plugin
is about.
3. Install all prerequisites (depends on the set of plugins you have
chosen in the previous step). 
4. In a console, run `sudo -E bash dummy-install.sh`. Re-login in the shell.
You are ready!  **NOTE:** this is the experimental part, and currently
only minimalist bash set-up is available via `dummy-install.sh`.
The development of _zsh-vimmer_ and _fully-fledged zsh-vimmer_ set-ups
is already on my mind.

Another way to install is to put each configuration file in the place
where it should be. The map below can help.

## Location Map

|    | common prefix | destination |
|:--:|:-------------:|:-----------:|
| **bash**| **~/** | .bashrc <br> .inputrc |
| **zsh/zshenv** | **~/** | .zshenv |
| **zsh/<_THE REST_>** | **$ZDOTDIR/** <br> better define it not to clutter **~** | .zshrc <br> extra.zsh <br> conda_autoenv.sh |
| **zsh/agnosterzak.zsh-theme** | **~/** | .zshenv |
| **jupyter** | **$JUPYTER_CONFIG_DIR/** <br> _if defined, otherwise,_ <br> **~/.jupyter/** | custom/custom.js <br> ngconfig/notebook.json |
| **tmux** | **$XDG_CONFIG_HOME/** <br><br> _if defined, otherwise,_ <br><br> **~/** | tmux/tmux.conf <br><br> _or in the latter case,_ <br><br> .tmux.conf |
| **anacron** | **/etc/** | anacrontab |
| **nvim** | **$XDG_CONFIG_HOME/nvim** <br> otherwise, you clutter **~** | init.vim |
