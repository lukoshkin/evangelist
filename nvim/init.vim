call plug#begin()

" --> Core plugins
Plug 'preservim/nerdtree'
Plug 'tpope/vim-surround'
Plug 'ctrlpvim/ctrlp.vim'

" Settings of both plugins can be found in 'mundo.vim'
if has('python3')
  Plug 'simnalamburt/vim-mundo'
else
  Plug 'mbbill/undotree'
endif

" --> Support functionality for old versions:
if v:version > 800 || has('nvim')
  Plug 'svermeulen/vim-yoink'
else
  Plug 'maxbrunsfeld/vim-yankstack'
endif

" --> Extra plugins that one may find useful
" Plug 'lervag/vimtex'
" Plug 'iamcco/markdown-preview.nvim',
"       \ { 'do': { -> mkdp#util#install() },
"       \ 'for': ['markdown', 'vim-plug']}
" Plug 'ycm-core/YouCompleteMe',
"       \ { 'do': 'python3 ./install.py
"       \ --clangd-completer --rust-completer' }

call plug#end()



" --> General Vim settings
source $XDG_CONFIG_HOME/nvim/conf/mappings.vim
source $XDG_CONFIG_HOME/nvim/conf/appearance.vim
source $XDG_CONFIG_HOME/nvim/conf/functionality.vim

" --> Core plugin settings
source $XDG_CONFIG_HOME/nvim/conf/nerdtree.vim
source $XDG_CONFIG_HOME/nvim/conf/mundo.vim
source $XDG_CONFIG_HOME/nvim/conf/ctrlp.vim

" --> Support functionality for old versions:
if v:version > 800 || has('nvim')
  source $XDG_CONFIG_HOME/nvim/conf/yoink.vim
else
  source $XDG_CONFIG_HOME/nvim/conf/yankstack.vim
endif

" --> Settings of the plugins commented out above
" source $XDG_CONFIG_HOME/nvim/conf/md-preview.vim
" source $XDG_CONFIG_HOME/nvim/conf/tex.vim
" source $XDG_CONFIG_HOME/nvim/conf/ycm.vim
