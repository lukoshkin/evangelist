ARG IMG_NAME=ubuntu:20.04
FROM $IMG_NAME

LABEL maintainer="lukoshkin.workspace@gmail.com" \
      repository="https://github.com/lukoshkin/evangelist" \
      description="This Dockerfile is a part of 'evangelist' project."

ENV USER=${USER:-evn}
## Set SHELL to get rid of errors in Tmux.
ENV HOME=${HOME:-/home/$USER} SHELL=/bin/bash
## Add a user if need be.
## NOTE: `&>` won't work for sh.
RUN if ! id -u $USER > /dev/null 2>&1; then \
      useradd -m -s /bin/bash $USER; \
    fi
## The first RUN uses 'requirements' files, the second ─ the rest.
COPY --chown=$USER:$USER . "$HOME/.config/evangelist/"

USER root
RUN cd $HOME/.config/evangelist \
    && bash sudo.builder.sh as_root \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US.UTF-8 \
    && npm install -g neovim \
    && gem install neovim \
    && chown -R $USER:$USER "$HOME"

USER $USER
RUN cd "$HOME/.config/evangelist" \
    && ./evangelist.sh install+ bash+
