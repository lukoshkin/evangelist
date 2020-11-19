# Vimmer Set-up 

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

# Installation

1. Clone the repository.
2. Go to `nvim` directory, look through the plugins to be installed
and their configs to be sourced. Comment out those lines you do not
agree with. Probably, you will have to google first what each plugin
is about.
3. Install all prerequisites (depends on the set of plugins you have
chosen in the previous step). 
4. In a console, run `bash dummy-install.sh`. Re-login in the shell. You are ready!
**NOTE:** this is the experimental part, and currently only minimalist bash set-up
is available via `dummy-install.sh`. The development of _zsh-vimmer_ and _fully-fledged
zsh-vimmer_ set-ups is already on my minds.

Another way to install is to put each configuration file in the place
where is should be. The map below can help.

**ToDo** "map"
