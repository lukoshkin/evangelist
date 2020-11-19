call plug#begin()

Plug 'preservim/nerdtree'
Plug 'simnalamburt/vim-mundo'
Plug 'svermeulen/vim-yoink'
Plug 'tpope/vim-surround'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'lervag/vimtex'
Plug 'iamcco/markdown-preview.nvim',
      \ { 'do': { -> mkdp#util#install() },
      \ 'for': ['markdown', 'vim-plug']}
Plug 'ycm-core/YouCompleteMe',
      \ { 'do': 'python3 ./install.py
      \ --clangd-completer --rust-completer' }

call plug#end()

source $XDG_CONFIG_HOME/nvim/confs/mappings.vim
source $XDG_CONFIG_HOME/nvim/confs/appearance.vim
source $XDG_CONFIG_HOME/nvim/confs/functionality.vim

source $XDG_CONFIG_HOME/nvim/confs/friendly-plugins.vim
source $XDG_CONFIG_HOME/nvim/confs/md-preview.vim
source $XDG_CONFIG_HOME/nvim/confs/nerdtree.vim
source $XDG_CONFIG_HOME/nvim/confs/ctrlp.vim
source $XDG_CONFIG_HOME/nvim/confs/yoink.vim
source $XDG_CONFIG_HOME/nvim/confs/ycm.vim
