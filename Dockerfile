ARG IMG_NAME=ubuntu:20.04
ARG SKIP_JUPYTER=false

FROM $IMG_NAME
SHELL ["/bin/bash", "-c"]
## To source ~/.bashrc (sh cannot execute bash files in general)
## and to enable some of bash syntax features.

LABEL maintainer="lukoshkin.workspace@gmail.com" \
      repository="https://github.com/lukoshkin/evangelist" \
      description="This Dockerfile is a part of 'evangelist' project"

ENV USER=${USER:-evn}
ENV HOME=${HOME:-/home/$USER} SHELL=/bin/bash
## Set SHELL to get rid of errors in Tmux.
ENV XDG_CACHE_HOME="$HOME/.cache" \
    XDG_CONFIG_HOME="$HOME/.config" \
    XDG_DATA_HOME="$HOME/.local/share"

USER root
RUN if ! id -u $USER &> /dev/null; then \
      ## Add a user if need be.
      useradd -m -s /bin/bash $USER; \
    fi \
    && mkdir -p "$HOME" \
        "$XDG_DATA_HOME" \
        "$XDG_CONFIG_HOME/evangelist" \
        "$XDG_CACHE_HOME/nvim/packer.nvim"

## Install all the libraries required by evangelist.
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get -qq update \
    && apt-get install -yq \
        build-essential libssl-dev cmake \
        pkg-config automake libtool-bin gettext \
        locales x11-xserver-utils uuid-runtime \
        git tmux wget curl ruby-full ripgrep tree \
        python3 python3-dev python3-pip \
        # zsh \
    # && chsh -s $(which zsh) \
    && curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
    && apt-get install -yq nodejs  \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

## Install Neovim (latest version)
## NOTE: `pkg-config automake libtool-bin gettext` might be
##        removed after the installation of Neovim from source.
RUN git clone https://github.com/neovim/neovim \
    && cd neovim && git checkout stable \
    && make CMAKE_BUILD_TYPE=Release \
    && make install \
    && npm install -g neovim \
    && gem install neovim \
    && cd .. && rm -rf neovim \
    ## Ensure everything in HOME belongs to USER.
    && chown -R $USER:$(id -gn $USER) "$HOME"

## Install Jupyter and its extensions
RUN if ! $SKIP_JUPYTER; then \
      pip3 install --no-cache-dir --upgrade \
        pip \
        pynvim \
        jupyter \
        jupyter_contrib_nbextensions \
        jupyter_nbextensions_configurator; \
    fi

USER $USER
COPY --chown=$USER . "$XDG_CONFIG_HOME/evangelist/"

## We need to source ~/.bashrc if conda is used.
RUN . ~/.bashrc \
    # . ~/.zshrc \
    && cd $XDG_CONFIG_HOME/evangelist \
    && ./evangelist.sh install+ bash+ \
    # && ./evangelist.sh install+ zsh+ \
    && if ! $SKIP_JUPYTER; then \
        ./evangelist.sh install jupyter; \
    fi

## WORKDIR is commented out, since the image is used on top of another,
## and we may want to preserve the original value.
# WORKDIR $HOME
