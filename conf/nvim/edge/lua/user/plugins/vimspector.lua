local keymap = require'lib.utils'.keymap

--- BP & BPCond & BPDisabled (green bullet) priorities are increased to 200.
vim.g.vimspector_sign_priority = {
  vimspectorPC            = 200,
  vimspectorPCBP          = 200,
  vimspectorBP            = 200,
  vimspectorBPCond        = 200,
  vimspectorBPDisabled    = 200,
  vimspectorCurrentThread = 200
  }


keymap('n', '<Leader>dc', '<Plug>VimspectorContinue')
keymap('n', '<Leader>dr', ':call vimspector#Reset()<CR>')

keymap('n', '<Leader>ds', '<Plug>VimspectorStop')
keymap('n', '<Leader>dd', '<Plug>VimspectorPause')
keymap('n', '<Leader>d0', '<Plug>VimspectorRestart')

keymap('n', '<Space>=', '<Plug>VimspectorStepInto')
keymap('n', '<Space>+', '<Plug>VimspectorStepOver')
keymap('n', '<Space>-', '<Plug>VimspectorStepOut')

keymap('n', '<Space>g', '<Plug>VimspectorRunToCursor')
keymap('n', '<Space>.', '<Plug>VimspectorToggleBreakpoint')
keymap('n', '<Space>,', '<Plug>VimspectorToggleConditionalBreakpoint')
keymap('n', '<Space>:', '<Plug>VimspectorAddFunctionBreakpoint')


function VariablesFocusToggle()
  if vim.fn.bufnr('vimspector.Variables') < 0 then
    return
  end

  if vim.fn.bufname() == 'vimspector.Variables' then
    vim.cmd 'MaximizerToggle'
    vim.fn.win_gotoid(vim.g.vimspector_session_windows.code)
  else
    vim.fn.win_gotoid(vim.g.vimspector_session_windows.variables)
    vim.cmd 'MaximizerToggle'
  end
end

keymap('n', '<Space>v', VariablesFocusToggle)
keymap('n', '<Space>mm', ':MaximizerToggle<CR>')