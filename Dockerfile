ARG IMG_NAME
FROM $IMG_NAME

ARG UID=1000
ARG GID=1000

ARG USER=vimmer
ARG HOME=/home/$USER

ENV XDG_CONFIG_HOME=$HOME/.config
ENV XDG_DATA_HOME=$HOME/.local/share
ENV XDG_CACHE_HOME=$HOME/.cache

USER root
RUN apt-get -qq update \
    && apt-get install -yq \
        python3 python3-dev python3-pip \
        git neovim tmux curl \
    && rm -rf \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*

RUN pip3 install --upgrade \
        pip \
        jupyter \
        jupyter_contrib_nbextensions \
        jupyter_nbextensions_configurator \
        neovim

WORKDIR $HOME
RUN if [ $USER = "vimmer" ]; then \
       groupadd -g $GID $USER \
       && useradd -u $UID -g $USER $USER \
       && chown -R $USER:$USER $HOME; \
    fi

USER $USER

RUN git clone https://github.com/lukoshkin/dotfiles.git \
    && cd dotfiles \
    && cat bash/bashrc >> ~/.bashrc \
    && cp tmux.conf ~/.tmux.conf \
    && cp bash/inputrc ~/.inputrc \
    && mkdir -p $XDG_CONFIG_HOME \
    && cp -r nvim $XDG_CONFIG_HOME/ \
    && curl -fLo $XDG_DATA_HOME/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

RUN vim +source $XDG_CONFIG_HOME/nvim/init.vim +q \
    && vim +PlugInstall +qall \
    && git clone https://github.com/lambdalisue/jupyter-vim-binding \
       $HOME/.local/share/jupyter/nbextensions/vim_binding \
    && jupyter nbextension enable vim_binding/vim_binding \
    && jupyter contrib nbextension install --user \
    && mkdir -p $HOME/.jupyter/custom && cd dotfiles \
    && cp jupyter/custom.js $HOME/.jupyter/custom/ \
    && cp jupyter/notebook.json $HOME/.jupyter/nbconfig
