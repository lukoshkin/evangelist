" Added when building Vundle
" >>> Vundle Configurations >>>
" -----------------------------
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'Valloric/YouCompleteMe'
Plugin 'davidhalter/jedi-vim'
Plugin 'simnalamburt/vim-mundo' 

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff two lines after
" -----------------------------
" <<< Vundle Configurations <<<

set colorcolumn=80
highlight ColorColumn ctermbg=darkgray

set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set smartindent

set number
highlight LineNr ctermfg=green ctermbg=darkgrey

"set textwidth=110
set cursorline
set lazyredraw

" Pattern searching
set hlsearch
set incsearch
" Press Space to turn off highlighting and clear any message 
" already displayed.
nnoremap <silent> <Space> :nohlsearch<Bar>:echo<CR>

" Provides tab-completion for all file-related tasks
set path+=**

" Display all matching files when tab complete
set wildmenu

inoremap jj <esc>
nnoremap m o<esc>
nnoremap <S-m> <S-o><esc>
let mapleader=","

" Run the currently edited file with python
xnoremap <leader>p :w !python<CR>
nnoremap <leader><S-p> :w !python<CR>

" Copy to clipboard
xnoremap <leader>y "+y
nnoremap <leader>y :%y+<CR>


" >>> Mundo-Related Settings >>>
" ------------------------------
nnoremap <leader>u :MundoToggle<CR>
" Enable persistent undo so that undo history persists across vim sessions
set undofile
set undodir=~/.vim/undo
" NOTE: Please, do not uncomment the two lines above if you do not set up
" autoremoval with crontab (better anacron). 
" [Keep the file executed by anacron in ~/.vim]
" ------------------------------
" <<< Mundo-Related Settings <<<


" >>> CtrlP Plugin Customization >>>
" ----------------------------------
set runtimepath^=~/.vim/bundle/ctrlp.vim
" Set no max file limit
"let g:ctrlp_max_files = 0

let g:ctrlp_working_path_mode = 'ra'
" 'r' - the nearest ancestor that contains one of these directories or
" files: .git .hg .svn .bzr _darcs, and your own root markers defined
" with the g:ctrlp_root_markers option.
" 'c' - the directory of the current file
" 'a' - like 'c', but only applies when the current working directory
" outside of CtrlP isn't a direct ancestor of the directory of the
" current file
" 0 or '' (empty string) - disable this feature

" *** ignore rc block1 ***
" Set this to 1 if you want CtrlP to scan for dotfiles and dotdirs:
let g:ctrlp_show_hidden = 0

set wildignore+=*/tmp/*,*.swp,*.zip ",*/.cache
set wildignore+=*/miniconda3,*/Music,*/Video
let g:ctrlp_custom_ignore = {
	\ 'dir':  '\v/\.(git|hg|ipynb_checkpoints)$',
	\ 'file': '\v\.(o|so|dll|ipynb|pdf)$',
	\ 'link': 'SOME_BAD_SYMBOLIC_LINKS',
	\ }
" *** ignore rc block1 ***

" NOTE: block1 does not apply when block2 is being used
" block2 works faster, so is more preferable

" *** ignore rc block2 ***
" Specify an external tool to use for listing files instead of using Vim's
" globpath(). Use %s in place of the target directory
let g:ctrlp_user_command = {
  \ 'types': {
    \ 1: ['.git', 'cd %s && git ls-files --exclude-standard --others'],
    \ 2: ['.hg', 'hg --cwd %s locate -I .'],
    \ },
  \ 'fallback': 'find %s -type f -readable 2> /dev/null |
    \ grep -vE "\/(\.|__)\w*" |
    \ grep -vE "(miniconda3|Music|Video|*\.(o|pdf|zip|gz|ipynb|JPG))"'
  \ }
" *** ignore rc block2 ***
" ----------------------------------
" <<< CtrlP Plugin Customization <<<


let g:ycm_global_ycm_extra_conf = "~/.vim/.ycm_extra_conf.py"
let g:ycm_confirm_extra_conf = 0
" << Turns off the suggestion to use ycm_conf found in the workdir
