ARG IMG_NAME
FROM $IMG_NAME

LABEL maintainer="lukoshkin@phystech.edu"
LABEL repository="https://github.com/lukoshkin/evangelist"
LABEL description="This Dockerfile is a part of 'evangelist' project"

ENV XDG_CONFIG_HOME="$HOME/.config"
ENV XDG_CACHE_HOME="$HOME/.cache"
ENV XDG_DATA_HOME="$HOME/.local/share"
## Set SHELL to get rid of errors in Tmux.
ENV SHELL /bin/bash

RUN mkdir -p "$XDG_CONFIG_HOME" \
    && mkdir -p "$XDG_CACHE_HOME" \
    && mkdir -p "$XDG_DATA_HOME" \
    && mkdir -p "$XDG_CONFIG_HOME/evangelist" \
    && mkdir -p "$XDG_CACHE_HOME/nvim/packer.nvim" \
    && chown -R ${USER:=evn}:$USER "$XDG_CACHE_HOME"

USER root
## Install all the libraries required by evangelist
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get -qq update \
    && apt-get install -yq \
        build-essential libssl-dev \
        pkg-config automake libtool-bin gettext \
        python3 python3-dev python3-pip \
        git tmux curl npm nodejs ruby-full \
        locales x11-xserver-utils uuid-runtime tree \
        # zsh \
    # && chsh -s $(which zsh) \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

## Install Neovim (latest version)
## NOTE: `pkg-config automake libtool-bin gettext` might be
##        removed after the installation of Neovim.
RUN git clone https://github.com/neovim/neovim \
    && cd neovim && git checkout stable \
    && make CMAKE_BUILD_TYPE=Release \
    && make install \
    && npm install -g neovim \
    && gem install neovim

## Install Jupyter and its extensions
RUN pip3 install --no-cache-dir --upgrade \
        pip \
        pynvim \
        jupyter \
        jupyter_contrib_nbextensions \
        jupyter_nbextensions_configurator

USER $USER
COPY --chown=$USER . "$XDG_CONFIG_HOME/evangelist/"
## To source ~/.bashrc (sh cannot execute bash files in general)
SHELL ["/bin/bash", "-c"]

## We need to source ~/.bashrc if conda is used.
RUN . ~/.bashrc \
    && cd $XDG_CONFIG_HOME/evangelist \
    && ./evangelist.sh install+ bash+ jupyter
    # && ./evangelist.sh install+ zsh+ jupyter
