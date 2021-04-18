" YCM highlighting
highlight YcmErrorSign ctermfg=DarkRed
highlight YcmWarningSign ctermfg=LightMagenta
highlight YcmErrorSection ctermfg=DarkRed
highlight YcmWarningSection ctermfg=LightMagenta

" gd - go to definition or declaration
" gK - open documentation (gk is mapped by default. See :help gk)
" <leader>qf - error fix if the compiler knows how
nnoremap <leader>qf :YcmCompleter FixIt<CR>
nnoremap gd :YcmCompleter GoToDefinitionElseDeclaration<CR>
nnoremap gK :YcmCompleter GetDoc<CR>


nnoremap <silent><leader>err :call YcmErrToggle()<CR>
" YCM gives the diagnostics in the location list window.
" Therefore, one can manage it with :lnext, :lprev, :lclose
" and the other relevant cmds.
nnoremap [g :lprev<CR>
nnoremap ]g :lnext<CR>
" Just FYI, both quickfix and location list store file positions.
" But the latter is window-local.

function! YcmErrToggle()
  if get(getloclist(0, {'winid':0}), 'winid', 0)
    lclose
  else
    YcmDiags
  endif
endfunction


" Close YCM diagnostics if it is the last window.
au! BufEnter * call YcmErrAutoExit()
" From https://vim.fandom.com
" Article's name: "Automatically quit Vim if quickfix window is the last"
"
function! YcmErrAutoExit()
  if &buftype=="quickfix"
    if winbufnr(2) == -1
      quit!
    endif
  endif
endfunction
" 'winbufnr({nr})' returns the number of buffer for the window {nr} requested
" So, if the second window is requested but doesn't exist the function will
" return '-1'

autocmd User YcmLocationOpened call s:CustomizeYcmLocationWindow()

function! s:CustomizeYcmLocationWindow()
  " Set the window height to 7.
  7wincmd _
  " Switch back to working window.
  wincmd p
endfunction
