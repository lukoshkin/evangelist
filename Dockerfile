ARG IMG_NAME
FROM $IMG_NAME

LABEL maintainer="lukoshkin@phystech.edu"
LABEL repository="https://github.com/lukoshkin/evangelist"
LABEL description="This Dockerfile is a part of 'evangelist' project"

ENV XDG_CONFIG_HOME="$HOME"/.config
ENV XDG_CACHE_HOME="$HOME"/.cache
ENV XDG_DATA_HOME="$HOME"/.local/share

RUN mkdir -p "$XDG_CONFIG_HOME" \
    && mkdir -p "$XDG_CACHE_HOME" \
    && mkdir -p "$XDG_DATA_HOME" \
    && mkdir -p "$XDG_CONFIG_HOME"/evangelist

USER root
## Install all the libraries required by evangelist
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get -qq update \
    && apt-get install -yq \
        python3 python3-dev python3-pip \
        git neovim tmux curl npm nodejs ruby-full \
        locales x11-xserver-utils uuid-runtime tree \
        # zsh \
    && npm install -g neovim \
    && gem install neovim \
    && locale-gen en_US.UTF-8 \
    # && chsh -s $(which zsh) \
    && rm -rf /var/lib/apt/lists/*

## Install Jupyter and its extensions
RUN pip3 install --no-cache-dir --upgrade \
        pip \
        pynvim \
        jupyter \
        jupyter_contrib_nbextensions \
        jupyter_nbextensions_configurator

USER $USER
COPY . "$XDG_CONFIG_HOME"/evangelist/

RUN cd $XDG_CONFIG_HOME/evangelist \
    && ./evangelist.sh install bash+ jupyter
    # && ./evangelist.sh install zsh+ jupyter
