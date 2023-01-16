ARG IMG_NAME=ubuntu:20.04
ARG SKIP_JUPYTER=true

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

USER root
RUN if ! id -u $USER &> /dev/null; then \
      ## Add a user if need be.
      useradd -m -s /bin/bash $USER; \
    fi; \
    export DEBIAN_FRONTEND=noninteractive \
    && apt-get -qq update \
    && apt-get install -yq \
        build-essential libssl-dev cmake \
        pkg-config automake libtool-bin gettext \
        locales x11-xserver-utils uuid-runtime \
        git tmux wget curl tree ninja-build \
        ruby-full ripgrep fd-find libxcb-xinerama0 \
        python3 python3-dev python3-pip \
        # zsh \
    # && chsh -s $(which zsh) \
    && curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
    && apt-get install -yq nodejs  \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/* \
    ## Install Neovim (latest version)
    ## NOTE: `pkg-config automake libtool-bin gettext` might be
    ##        removed after the installation of Neovim from source.
    && git clone https://github.com/neovim/neovim \
    && cd neovim && git checkout stable \
    && make CMAKE_BUILD_TYPE=Release \
    && make install \
    && npm install -g neovim \
    && gem install neovim \
    && cd .. && rm -rf neovim \
    ## Ensure everything in HOME belongs to USER.
    && mkdir $HOME/.config && chown -R $USER:$(id -gn $USER) "$HOME" \
    ## Upgrade pip and install pynvim & IPython.
    && pip3 install --no-cache-dir --upgrade pip pynvim ipython

## Install Jupyter and its extensions
RUN if ! $SKIP_JUPYTER; then \
      pip3 install --no-cache-dir --upgrade \
        jupyter jupyter_contrib_nbextensions \
        jupyter_nbextensions_configurator; \
    fi

USER $USER
COPY --chown=$USER:$USER . "$HOME/.config/evangelist/"

RUN cd "$HOME/.config/evangelist" \
    && ./evangelist.sh install+ bash+ \
    # && ./evangelist.sh install+ zsh+ \
    && if ! $SKIP_JUPYTER; then \
        ./evangelist.sh install jupyter; \
    fi

## We don't use WORKDIR, since the image may be used on top of another.
## In this case, preserving the original value might be more preferable.
