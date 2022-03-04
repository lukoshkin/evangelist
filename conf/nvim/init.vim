"" General Vim settings
source $XDG_CONFIG_HOME/nvim/conf/mappings.vim
source $XDG_CONFIG_HOME/nvim/conf/appearance.vim
source $XDG_CONFIG_HOME/nvim/conf/functionality.vim


call plug#begin()

"" Core plugins
source $XDG_CONFIG_HOME/nvim/conf/nerdtree.vim
source $XDG_CONFIG_HOME/nvim/conf/ctrlp.vim
source $XDG_CONFIG_HOME/nvim/conf/mundo.vim
Plug 'mhinz/vim-startify'

"" Extra plugins that one might find useful
" source $XDG_CONFIG_HOME/nvim/conf/tex.vim
" source $XDG_CONFIG_HOME/nvim/conf/regex.vim
" source $XDG_CONFIG_HOME/nvim/conf/md-preview.vim
" source $XDG_CONFIG_HOME/nvim/conf/translate.vim
" Plug 'tpope/vim-surround'

"" 'Towards IDE' plugins
" source $XDG_CONFIG_HOME/nvim/conf/slime.vim
" source $XDG_CONFIG_HOME/nvim/conf/ipython.vim
" source $XDG_CONFIG_HOME/nvim/conf/vimspector.vim
" Plug 'tpope/vim-commentary'

"" Use either CoC or YCM (!)
" source $XDG_CONFIG_HOME/nvim/conf/coc.vim
" source $XDG_CONFIG_HOME/nvim/conf/ycm.vim

"" Import user-defined settings
"" (including plugins of their preferences)
if filereadable($EVANGELIST."/custom/custom.vim")
  source $EVANGELIST/custom/custom.vim
endif

call plug#end()
