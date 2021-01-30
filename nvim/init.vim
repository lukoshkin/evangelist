call plug#begin()

Plug 'preservim/nerdtree'
Plug 'svermeulen/vim-yoink'
Plug 'tpope/vim-surround'
Plug 'ctrlpvim/ctrlp.vim'

if has('python3')
  Plug 'simnalamburt/vim-mundo'
else
  Plug 'mbbill/undotree'
endif
" Plug 'lervag/vimtex'
" Plug 'iamcco/markdown-preview.nvim',
"       \ { 'do': { -> mkdp#util#install() },
"       \ 'for': ['markdown', 'vim-plug']}
" Plug 'ycm-core/YouCompleteMe',
"       \ { 'do': 'python3 ./install.py
"       \ --clangd-completer --rust-completer' }

call plug#end()

source $XDG_CONFIG_HOME/nvim/conf/mappings.vim
source $XDG_CONFIG_HOME/nvim/conf/appearance.vim
source $XDG_CONFIG_HOME/nvim/conf/functionality.vim

source $XDG_CONFIG_HOME/nvim/conf/nerdtree.vim
source $XDG_CONFIG_HOME/nvim/conf/mundo.vim
source $XDG_CONFIG_HOME/nvim/conf/ctrlp.vim
source $XDG_CONFIG_HOME/nvim/conf/yoink.vim
" source $XDG_CONFIG_HOME/nvim/conf/md-preview.vim
" source $XDG_CONFIG_HOME/nvim/conf/tex.vim
" source $XDG_CONFIG_HOME/nvim/conf/ycm.vim
