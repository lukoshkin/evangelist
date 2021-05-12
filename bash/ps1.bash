
# Customize cmd prompt
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
WHITE=$(tput setaf 7)

BOLD=$(tput bold)
RESET=$(tput sgr0)

PROMPT_DIRTRIM=2
[[ -n $PROMPT_COMMAND ]] && PROMPT_COMMAND+=';'

PROMPT_COMMAND+='\
  [[ -n $CONDA_DEFAULT_ENV ]] \
    && ENV=" $(basename $CONDA_DEFAULT_ENV)" || ENV='

PS1="\[$GREEN\]\h\[$YELLOW\]@\[$BOLD\]\u \[$WHITE\]\w\[$RESET\]\[$BLUE\]\$ENV \[$RESET\]$ "
unset GREEN YELLOW BLUE WHITE BOLD RESET

