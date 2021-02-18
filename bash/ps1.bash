
# Customize cmd prompt
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
WHITE=$(tput setaf 15)
BLUE="\\[\e[0;34m\\]"

BOLD=$(tput bold)
RESET="\\[\e[m\\]"

PROMPT_DIRTRIM=2
PROMPT_COMMAND='\
  [[ -n $CONDA_DEFAULT_ENV ]] \
    && ENV=" $(basename $CONDA_DEFAULT_ENV)" || ENV='

PS1="${GREEN}\h${YELLOW}@${BOLD}\u ${WHITE}\w${BLUE}\$ENV $RESET$ "
unset GREEN YELLOW WHITE BLUE BOLD RESET

