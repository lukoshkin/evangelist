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

" --> Settings of the plugins commented out above
" source $XDG_CONFIG_HOME/nvim/conf/md-preview.vim
" source $XDG_CONFIG_HOME/nvim/conf/tex.vim
" source $XDG_CONFIG_HOME/nvim/conf/ycm.vim


" Import user-defined settings
if filereadable($EVANGELIST."/custom/custom.vim")
  source $EVANGELIST/custom/custom.vim
endif
