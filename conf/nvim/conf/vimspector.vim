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
