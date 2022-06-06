vim.g.qs_highlight_on_keys = { 'f', 'F', 't', 'T' }

local aug = vim.api.nvim_create_augroup('QS_Colors', { clear=true })

vim.api.nvim_create_autocmd('ColorScheme', {
  command =
    "hi QuickScopePrimary " ..
    "guifg='PaleVioletRed' gui=underline " ..
    "ctermfg=211 cterm=underline",
  group = aug
})

vim.api.nvim_create_autocmd('ColorScheme', {
  command =
    "hi QuickScopeSecondary " ..
    "guifg='RosyBrown3' gui=undercurl " ..
    "ctermfg=138 cterm=undercurl",
  group = aug
})


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
    "" Change here highlighting of elements like
    "" CursorLine, ColorColumn; spellchecker, and others.

    "" '!' here means that there will be no error
    "" if the highlighting it refers to is already exists.
    hi! SpellBad   guifg=none guibg=none gui=undercurl guisp=palevioletred
    hi! SpellCap   guifg=none guibg=none gui=undercurl guisp=khaki1
    hi! SpellRare  guifg=none guibg=none gui=undercurl guisp=mediumpurple1
    hi! SpellLocal guifg=none guibg=none gui=undercurl guisp=skyblue1
    "" TODO: check if cterm attributes need to be added.

    "" Pattern matching for au is different:
    "" to exclude buffer names with leading underscores, we put
    "" 'negative lookbehind' after the star expression.
    au! BufWinLeave *\(_\)\@<! call DeleteTWSAttrs()
    au! BufWinEnter,WinEnter *\(_\)\@<! call MatchTWS()
    au! WinLeave *\(_\)\@<! call ClearTWSMatch()
    au! InsertLeave * call MatchTWS()
  endfunction

  "" Trailing whitespace highlighting
  "" FIXME: match is highlighted even during typing in the insert mode.
  function! MatchTWS ()
    if len(bufname()) == 0 || !&modifiable
      return
    endif

    if &ft != 'markdown'
      let g:tws_color_any = get(g:, 'tws_color_any', 'palevioletred')
      let l:cmd = 'hi TrailingWS ctermbg=211 guibg='.g:tws_color_any
      execute(l:cmd)
    else
      let g:tws_color_md = get(g:, 'tws_color_md', 'rosybrown')
      let l:cmd = 'hi TrailingWS ctermbg=211 guibg='.g:tws_color_md
      execute(l:cmd)
    endif

    if !exists('b:tws_bnr')
      let w:tws_mid = matchadd('TrailingWS', '\s\+$')
      let b:tws_bnr = bufnr()
    endif

    if !exists('w:tws_mid')
      let w:tws_mid = matchadd('TrailingWS', '\s\+$')
    endif
  endfunction

  "" NOTE: the following two functions can be merged into one
  "" by adding argument passing to API
  function! ClearTWSMatch ()
    if exists('b:tws_bnr') && exists('w:tws_mid')
      call matchdelete(w:tws_mid)
      unlet w:tws_mid
    endif
  endfunction

  function! DeleteTWSAttrs ()
    "" NOTE: If-condition will never evaluate to true on WinEnter.
    if exists('b:tws_bnr') && b:tws_bnr == expand('<abuf>')
      unlet b:tws_bnr
      if exists('w:tws_mid')
        call matchdelete(w:tws_mid)
        unlet w:tws_mid
      endif
    endif
  endfunction

  colorscheme nord
]])
