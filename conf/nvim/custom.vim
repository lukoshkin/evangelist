"" RUN `exec $SHELL` AFTER MODIFYING THIS FILE.

"" CUSTOM MAPPINGS
"" ---------------
"" Some plugins use <localleader> to make mappings defined with the use of it
"" local to a buffer. That is, same mappings get different meanings
"" in different buffers.
let maplocalleader="\<Space>"

"" Moving lines up or down (with re-indentation).
"" https://vim.fandom.com/wiki/Moving_lines_up_or_down
nnoremap <C-j> :m+<CR>==
nnoremap <C-k> :m-2<CR>==
" inoremap <C-j> <Esc>:m+<CR>==gi
" inoremap <C-k> <Esc>:m-2<CR>==gi
vnoremap <C-j> :m'>+<CR>gv=gv
vnoremap <C-k> :m-2<CR>gv=gv


"" CUSTOM OPTIONS
"" --------------
"" Switch to another buffer even if the current one is modified.
"" (Can lead to closing of hidden buffers without saving if using
""  such exit options like `<prefix>-Q` in Tmux. Likely, a swap file
""  will be created in this case, so no data will be lost). By default,
"" it is 'off' in Vim and 'on' in Neovim latest versions.
" set hidden

"" ru2en mapping in all modes but insert.
"" Change the symbols inserted (ru or en) with <C-^>.
"" A good alternative would be 'lyokha/vim-xkbswitch' plugin.
set keymap=russian-jcukenwin
"" start from 'en' (since defaults were changed on the line above).
set iminsert=0
set imsearch=0

"" Start scrolling before reaching the screen borders.
" set scrolloff=8
" set sidescrolloff=8

set nowrap
"" Break sentences (not words) exceeding 110 character width.
"" For this to work, the above line should be commented out.
" set textwidth=110

"" Instead of highlighting, one can use special chars for
"" trailing spaces and tabs.
" set list
" set listchars=tab:▸\ ,trail:·


"" CUSTOM COLORS
"" -------------
augroup CustomColors
  autocmd!
  autocmd ColorScheme * call CustomHighlighting()
  "" The non-modified highlighting below is geared towards
  "" 'nord' theme; thus, instead of '*' event, we could
  "" directly specify 'nord'.
augroup END

function CustomHighlighting() abort
  "" Change here highlighting for elements like
  "" CursorLine, ColorColumn; spellchecker, and others.

  "" '!' here means that there will be no error
  "" if the highlighting it refers to is already exists.
  hi! SpellBad   guifg=NONE guibg=NONE gui=undercurl guisp=palevioletred
  hi! SpellCap   guifg=NONE guibg=NONE gui=undercurl guisp=khaki1
  hi! SpellRare  guifg=NONE guibg=NONE gui=undercurl guisp=mediumpurple1
  hi! SpellLocal guifg=NONE guibg=NONE gui=undercurl guisp=skyblue1
  "" NOTE: Vim requires 'none' to be uppercase.
endfunction


Plug 'arcticicestudio/nord-vim'
silent! colorscheme nord
