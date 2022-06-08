--- #Quick Scope
vim.g.qs_highlight_on_keys = { 'f', 'F', 't', 'T' }

local aug_qs = vim.api.nvim_create_augroup('QS_Colors', { clear=true })

vim.api.nvim_create_autocmd('ColorScheme', {
  command =
    "hi QuickScopePrimary " ..
    "guifg='PaleVioletRed' gui=underline " ..
    "ctermfg=211 cterm=underline",
  group = aug_qs
})

vim.api.nvim_create_autocmd('ColorScheme', {
  command =
    "hi QuickScopeSecondary " ..
    "guifg='RosyBrown3' gui=undercurl " ..
    "ctermfg=138 cterm=undercurl",
  group = aug_qs
})


--- #IPython Cell
--- If not modifying hl for IPythonCell, it will be the same
--- as the Folded hl. Currently there is no hl for Folded.
local aug_ipc = vim.api.nvim_create_augroup(
  'IPythonCellHighlight', {clear=true})

vim.api.nvim_create_autocmd('ColorScheme', {
  command = 'hi! IPythonCell ctermbg=238 guifg=darkgrey guibg=#444d56',
  group = aug_ipc
})


--- #Nord Theme
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

    "" '!' here means create even if it is already exists.
    hi! SpellBad   guifg=none guibg=none gui=undercurl guisp=palevioletred
    hi! SpellCap   guifg=none guibg=none gui=undercurl guisp=khaki1
    hi! SpellRare  guifg=none guibg=none gui=undercurl guisp=mediumpurple1
    hi! SpellLocal guifg=none guibg=none gui=undercurl guisp=skyblue1
    "" TODO: check if cterm attributes need to be added.

    "" Negative lookbehind since it is unlikely that it will be
    "" trailing underscores after a filename's extension.
    au! BufWinEnter,WinEnter *\(_\)\@<! call MatchTWS()
    "" BufWinLeave should not trigger MatchTWS; otherwise, plugins
    "" like nvim-notify or fidget, that rely on floating windows, will
    "" clear match groups after their buffers are removed from a window.
    au! WinLeave *\(_\)\@<! call ClearTWSMatch()
    au! InsertLeave * call MatchTWS()
  endfunction

  "" Trailing whitespace highlighting
  "" FIXME: match is highlighted even during typing in the insert mode.
  function! MatchTWS ()
    "" Not sure about `search()` performance. If it is comparable
    "" to calls of `matchadd()` and `hi`, then the amount of work in
    "" the function is doubled.
    let l:pos = getpos('.')
    if len(bufname()) == 0 || !&modifiable || search('\s\+$') <= 0
      return
    else
      call setpos('.', l:pos)
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

    let l:winid = win_getid()
    if !exists('g:tws_wins')
      let g:tws_wins = { l:winid: matchadd('TrailingWS', '\s\+$') }
    else
      if !has_key(g:tws_wins, l:winid)
        let g:tws_wins[l:winid] = matchadd('TrailingWS', '\s\+$')
      else
        "" If matches were removed with `clearmatches()`,
        "" checking the length of getmatches() list may help.
        if g:tws_wins[l:winid] < 0 || len(getmatches()) == 0
          let g:tws_wins[l:winid] = matchadd('TrailingWS', '\s\+$')
        endif
      endif
    endif
  endfunction

  function! ClearTWSMatch ()
    let l:winid = win_getid()
    if (exists('g:tws_wins')
          \ && has_key(g:tws_wins, l:winid)
          \ && g:tws_wins[l:winid] >= 0)
        call matchdelete(g:tws_wins[l:winid])
        let g:tws_wins[l:winid] = -1
    endif
  endfunction

  colorscheme nord
]])
