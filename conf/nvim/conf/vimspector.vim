Plug 'puremourning/vimspector'

nmap <leader>dc <Plug>VimspectorContinue
nmap <leader>dr :call vimspector#Reset()<CR>

nmap <leader>ds <Plug>VimspectorStop
nmap <leader>dd <Plug>VimspectorPause
nmap <leader>d0 <Plug>VimspectorRestart

nmap <Space>= <Plug>VimspectorStepInto
nmap <Space>+ <Plug>VimspectorStepOver
nmap <Space>- <Plug>VimspectorStepOut

nmap <Space>g <Plug>VimspectorRunToCursor
nmap <Space>. <Plug>VimspectorToggleBreakpoint
nmap <Space>, <Plug>VimspectorToggleConditionalBreakpoint
nmap <Space>: <Plug>VimspectorAddFunctionBreakpoint


"" BP & BPCond & BPDisabled (green bullet) priorities are increased to 200.
let g:vimspector_sign_priority = {
  \    'vimspectorPC':            200,
  \    'vimspectorPCBP':          200,
  \    'vimspectorBP':            200,
  \    'vimspectorBPCond':        200,
  \    'vimspectorBPDisabled':    200,
  \   'vimspectorCurrentThread':  200
  \ }


"" Should `vim-maximizer` be added in a separate file?
Plug 'szw/vim-maximizer'
nnoremap <silent><Space>mm :MaximizerToggle<CR>
nnoremap <Space>vv :silent! call ToggleVimspectorVariables()<CR>


fun! ToggleVimspectorVariables()
  if bufnr('vimspector.Variables') < 0
    return
  endif

  if bufname() == 'vimspector.Variables'
    MaximizerToggle
    call win_gotoid(g:vimspector_session_windows.code)
  else
    call win_gotoid(g:vimspector_session_windows.variables)
    MaximizerToggle
  endif
endfun
