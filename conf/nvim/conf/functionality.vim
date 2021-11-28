" Provide tab-completion for all file-related tasks.
set path+=**

" Display all matching files when tab complete.
set wildmenu

" Buffer updates instead of updating all the time.
set lazyredraw

" Switch to another buffer even if the current one is modified.
" set hidden


" Mouse support
if !has('nvim')
  execute "set <A-m>=\em"
endif

noremap <A-m> :call ToggleMouse()<CR>
inoremap <A-m> <Esc>:call ToggleMouse()<CR>a

" https://unix.stackexchange.com/questions/156707
function! ToggleMouse()
    " check if mouse is enabled
    if &mouse == 'a'
        " disable mouse
        set mouse=
    else
        " enable mouse everywhere
        set mouse=a
    endif
endfunc


" ru2en mapping in all modes but insert.
" Change the symbols inserted (ru or en) with <C-^>.
" A good alternative would be 'lyokha/vim-xkbswitch' plugin.
set keymap=russian-jcukenwin
" start from 'en'
set iminsert=0
set imsearch=0


" Set case-insensitive search and command modes as default.
set ignorecase
set smartcase
" 'smartcase' option switches from insensitive to sensitive search mode
" whenever there is a capital letter in a pattern. One can use '\C' or \c'
" escape sequences anywhere in the pattern to make the search case-sensitive
" or -insensitive, respectively, regardless of these two options.


" Don't insert two spaces after a '.', '?' and '!' with a join command.
set nojoinspaces
