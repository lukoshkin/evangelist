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
    && mkdir -p "$XDG_DATA_HOME"

USER root
# Install all the libraries required by Neovim
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get -qq update \
    && apt-get install -yq \
        python3 python3-dev python3-pip \
        git neovim tmux curl npm nodejs \
        ruby-full locales x11-xserver-utils tree \
    && npm install -g neovim \
    && gem install neovim \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Install Jupyter and its extensions
RUN pip3 install --no-cache-dir --upgrade \
        pip \
        pynvim \
        jupyter \
        jupyter_contrib_nbextensions \
        jupyter_nbextensions_configurator

USER $USER
# Download configs and distribute them to their locations
RUN cd ~ && git clone https://github.com/lukoshkin/evangelist.git \
    && cd evangelist \
    && if [ -f ~/.bashrc ]; \
       then \
         sed -n '/> RESERVED-CONFS/,/< RESERVED-CONFS/{//!p}' \
         ~/.bashrc >> bash/bashrc; \
       fi \
    && mv bash/bashrc ~/.bashrc \
    && mv tmux/tmux.conf ~/.tmux.conf \
    && mv bash/inputrc ~/.inputrc \
    && cp -R nvim "$XDG_CONFIG_HOME"/ \
    && sed -e '/^source .*\/bash\/aliases-functions\.sh/ \
         {r bash/aliases-functions.sh' -e 'd}' -i ~/.bashrc \
    && cat bash/ps1.bash >> ~/.bashrc \
    && echo "source ~/.bashrc" > ~/.profile \
    && sed -i '1i set-option -g default-shell /bin/bash' ~/.tmux.conf \
    && curl -fLo "$XDG_DATA_HOME"/nvim/site/autoload/plug.vim --create-dirs \
         https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
    && JUPVIM="$(jupyter --data-dir)/nbextensions/vim_binding" \
    && if [ -d "$JUPVIM" ]; then rm -rf "$JUPVIM"; fi \
    && git clone https://github.com/lambdalisue/jupyter-vim-binding "$JUPVIM" \
    && jupyter nbextension enable vim_binding/vim_binding \
    && jupyter contrib nbextension install --user \
    && mkdir -p ~/.jupyter/custom \
    && mv jupyter/custom.js ~/.jupyter/custom/ \
    && mv jupyter/notebook.json ~/.jupyter/nbconfig \
    && nvim --headless +PlugInstall +qall \
    && rm -rf ~/evangelist

