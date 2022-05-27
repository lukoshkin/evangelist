vim.g.nord_contrast = true
vim.g.nord_borders = true
vim.g.nord_italic = false

vim.cmd([[
    augroup CustomColors
      autocmd!
      autocmd ColorScheme * call CustomHighlighting()
      "" The non-modified highlighting below is geared towards
      "" 'nord' theme; thus, instead of '*' event, we could
      "" directly specify 'nord'.
    augroup END

    function! CustomHighlighting() abort
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
      au! BufWinEnter *\(_\)\@<! if len(bufname()) > 0
        \| match ExtraWhitespace /\s\+$/
        \| endif

      au! InsertEnter * if len(bufname()) > 0
        \| match ExtraWhitespace /\s\+\%#\@<!$/
        \| endif

      au! InsertLeave * if len(bufname()) > 0
        \| match ExtraWhitespace /\s\+$/
        \| endif

      au! BufWinLeave *\(_\)\@<! call clearmatches()
    endfunction

    colorscheme nord
]])
