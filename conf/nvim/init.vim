"" Think of putting these two imports after `call plug#end()`
"" to give them more preference. Though, there are no overrides
"" to my knowledge.
source $XDG_CONFIG_HOME/nvim/conf/mappings.vim
source $XDG_CONFIG_HOME/nvim/conf/options.vim

call plug#begin()

"" Core plugins
source $XDG_CONFIG_HOME/nvim/conf/nerdtree.vim
source $XDG_CONFIG_HOME/nvim/conf/ctrlp.vim
source $XDG_CONFIG_HOME/nvim/conf/mundo.vim

"" Easier Vim with startup page and resuming file from where you left off,
"" pasting with auto-indentation, and auto-deduction of file indentation.
"" `eunuch` plugin adds useful commands (like :SudoWrite), `repeat` allows
"" to repeat actions that include plugin commands (<Plug> and so on).
Plug 'mhinz/vim-startify'
Plug 'farmergreg/vim-lastplace'
Plug 'lukoshkin/trailing-whitespace', { 'branch': 'vimscript' }
Plug 'jessarcher/vim-heritage'

Plug 'sickill/vim-pasta'
Plug 'tpope/vim-sleuth'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-repeat'

"" Extra plugins that one might find useful
" source $XDG_CONFIG_HOME/nvim/conf/tex.vim
" source $XDG_CONFIG_HOME/nvim/conf/regex.vim
" source $XDG_CONFIG_HOME/nvim/conf/md-preview.vim
" source $XDG_CONFIG_HOME/nvim/conf/floaterm.vim

"" 'Towards IDE' plugins
" source $XDG_CONFIG_HOME/nvim/conf/slime.vim
" source $XDG_CONFIG_HOME/nvim/conf/ipython.vim
" source $XDG_CONFIG_HOME/nvim/conf/vimspector.vim

"" Use either CoC or YCM (!)
" source $XDG_CONFIG_HOME/nvim/conf/coc.vim
" source $XDG_CONFIG_HOME/nvim/conf/ycm.vim

"" Import user-defined settings
"" (including plugins of their preferences)
if filereadable($EVANGELIST."/custom/.plugins.vim")
  source $EVANGELIST/custom/.plugins.vim
endif

call plug#end()

if filereadable($EVANGELIST."/custom/.settings.vim")
  source $EVANGELIST/custom/.settings.vim
endif

call plug#end()
