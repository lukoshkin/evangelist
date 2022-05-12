"" Run `exec $SHELL` after modifying this file.

"" Some plugins use <localleader> to make mappings defined with the use of it
"" local to a buffer. That is, same mappings get different meanings
"" in different buffers.
let maplocalleader="\<Space>"


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
  hi! SpellBad   guifg=none guibg=none gui=undercurl guisp=palevioletred
  hi! SpellCap   guifg=none guibg=none gui=undercurl guisp=khaki1
  hi! SpellRare  guifg=none guibg=none gui=undercurl guisp=mediumpurple1
  hi! SpellLocal guifg=none guibg=none gui=undercurl guisp=skyblue1

  "" Trailing whitespace highlighting
  highlight! ExtraWhitespace ctermbg=red guibg=palevioletred
  au! FileType markdown hi ExtraWhitespace ctermbg=brown guibg=rosybrown

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
endfunction


Plug 'arcticicestudio/nord-vim'
colorscheme nord
