set colorcolumn=80
highlight ColorColumn ctermbg=darkgray

" Spell checker highlighting
hi SpellBad ctermfg=white ctermbg=darkred cterm=none
hi SpellCap ctermfg=black ctermbg=green cterm=none
hi SpellRare ctermfg=black ctermbg=magenta cterm=none
hi SpellLocal ctermfg=black ctermbg=cyan cterm=none
" The 'cterm' attr specifies the font: bold, underline, undercurl,
" (in/re)verse, italic, standout, strikethrough, NONE
" -----------------
"  Rare words = MAGENTA
"  Lower-case words after full stop = GREEN
"  Misspelled  ones = DARK RED
"  spellchecker is US, word is British = CYAN

set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
set smartindent

set number relativenumber
highlight LineNr ctermfg=green ctermbg=darkgrey

" set textwidth=110
set cursorline
set lazyredraw

" Pattern searching (highlighting and search before <Enter> hit)
set hlsearch
set incsearch
