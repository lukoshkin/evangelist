"" Colors
set background=dark
colorscheme ron
syntax on
"" `syntax on` is used here to enforce the order of settings declaration
"" in Neovim 0.4.3 (no information about earlier versions). Without it,
"" colors for `ColorColumn` and etc. (defined below) are overwritten by
"" `colorscheme ron`, though the former appear after the latter.

"" 80 character width marker
set colorcolumn=80
highlight ColorColumn ctermbg=darkgray

"" Highlighting for the current line
set cursorline
highlight CursorLine cterm=bold ctermbg=238

"" Better numbering
set number relativenumber
highlight LineNr ctermfg=green ctermbg=darkgray

"" Break sentences exceeding 110 character width
" set textwidth=110

"" Spell checker highlighting
hi SpellBad ctermfg=white ctermbg=darkred cterm=none
hi SpellCap ctermfg=black ctermbg=green cterm=none
hi SpellRare ctermfg=black ctermbg=magenta cterm=none
hi SpellLocal ctermfg=black ctermbg=cyan cterm=none
"" The 'cterm' attr specifies the font: bold, underline, undercurl,
"" (in/re)verse, italic, standout, strikethrough, NONE
"" ---------------------
""  Rare words = MAGENTA
""  Lower-case words after full stop = GREEN
""  Misspelled ones = DARK RED
""  spellchecker is US, word is British = CYAN

"" Default indentation
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
set smartindent


"" Pattern searching (highlighting and search before <Enter> hit)
set hlsearch
set incsearch

"" Incremental hl-search when replacing (for Neovim)
if has('nvim')
  set inccommand=nosplit
endif


"" Trailing whitespace highlighting
highlight! ExtraWhitespace ctermbg=red guibg=red
au! FileType markdown hi ExtraWhitespace ctermbg=brown guibg=brown

"" Pattern matching for au is different:
"" to exclude buffer names with leading underscores, we put
"" 'negative lookbehind' after the star expression.
au! BufWinEnter *\(_\)\@<! match ExtraWhitespace /\s\+$/
au! InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
au! InsertLeave * match ExtraWhitespace /\s\+$/
au! BufWinLeave *\(_\)\@<! call clearmatches()

"" Instead of highlighting, one can use special chars for
"" trailing spaces and tabs.
" set list
" set listchars=tab:▸\ ,trail:·
