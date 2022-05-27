vim.g.ipython_cell_tag = {'# %%', '#%%', '## <codecell>', '# In['}
--- Use %cpaste "magic function" that allows for error-free pasting.
--- Moreover, it sends all lines in a cell at once instead of one by one.
vim.g.slime_python_ipython = 1

--- The setting below work only in a tmux session when
--- Vim is open in the left pane, and Ipython in the right one.
vim.api.nvim_create_user_command('Run', 'Run :IpythonCellRun', {})
vim.api.nvim_create_user_command('RunTime', 'Run :IpythonCellRunTime', {})
vim.api.nvim_create_user_command('Clear', 'Run :IpythonCellClear', {})

-- command! Run :IPythonCellRun
-- command! RunTime :IPythonCellRunTime
-- command! Clear :IPythonCellClear

--- (*) solves bug1 in some way.
local slime_send_jump = function ()
  vim.cmd[[
    execute "normal \<Plug>SlimeSendCell"
    IPythonCellNextCell
  ]]
end

--- DISCLAIMER:
--- Notice below and all other comments are from Neovim<0.5 settings.
--- The code below is a dirty way to set local mapping. Define mappings
--- instead in vim after/ftplugin/python.vim, using <localleader>.

--- Note: the order of sourcing Slime and IPython configs does matter.
--- ####  First, import Slime's one, then those of IPython.
--- 1. Cell execution (bug 1).
--- 2. Execute and jump to the next cell (bug 1).
--- 3. Send cell with slime (*) and jump to the next one
---    (NOTE: it overrides SlimeSendCell mapping).
--- 4. Jump to the next cell.
--- 5. Jump to the previous one.
--- 6. Close all matplotlib figure windows.
--- 7. Restart the kernel (bug 2).
local aug = vim.api.nvim_create_augroup('IpyCells', {clear=true})

local pyau = function (lhs, cmd)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'python',
    callback = function ()
      vim.keymap.set('n', lhs, cmd)
    end,
    group = aug,
  })
end


pyau('<CR>', ':IPythonCellExecuteCell<CR>')
pyau('<Leader><CR>', slime_send_jump)
pyau('<Space>n', ':IPythonCellNextCell<CR>')
pyau('<Space>p', ':IPythonCellPrevCell<CR>')
pyau('<Space>x', ':IPythonCellClose<CR>')
pyau('<Space>00', ':IPythonCellRestart<CR>')
