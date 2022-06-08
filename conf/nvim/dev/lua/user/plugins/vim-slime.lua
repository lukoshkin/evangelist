vim.g.slime_target = 'neovim'
vim.g.slime_dont_ask_default = 1
vim.g.slime_cell_delimiter = '#%%'

--- To send just a line, use <C-c><C-c> (default mapping).
--- Send text delimited by #%% (emulation of cells) with <C-s>.
vim.keymap.set('n', '<leader><CR>', '<Plug>SlimeSendCell')
--- NOTE: <Plug>(SlimeSendCell) won't work here.

local function start_slime_session (cmd)
  local tab_var = vim.api.nvim_tabpage_get_var
  local tnr = vim.api.nvim_tabpage_get_number(0)

  if vim.fn.bufnr('BottomTerm') < 0 then
    vim.fn.BottomtermToggle(cmd)
  else
    if vim.fn.bufwinid('BottomTerm') < 0 then
      vim.fn.BottomtermToggle()
    end

    --- NOTE: BottomtermToggle restores focus on a window from
    --- which it was called if 'bottom_term_focus_on_win' is true.
    vim.fn.win_gotoid(vim.fn.bufwinid('BottomTerm'))
    local tji = vim.api.nvim_buf_get_var(0, 'terminal_job_id')
    vim.fn.chansend(tji, "'" .. cmd .. "'\n")
  end

  if tab_var(tnr, 'bottom_term_horizontal') then
    vim.fn.BottomtermOrientation()
  end

  vim.g.slime_default_config = {
    jobid = tab_var(tnr, 'bottom_term_channel'),
    target_pane = '{top-right}',
  }
end

local function start_ipython_session ()
  vim.g.bottom_term_focus_on_win = true
  local check = 'pip3 --disable-pip-version-check list '
  check = check .. [[| grep -P 'matplotlib(?!-inline)' > /dev/null]]

  local cmd = 'ipython'
  if os.execute(check) == 0 then
    cmd = cmd .. ' --matplotlib'
  end

  start_slime_session(cmd)
end

vim.keymap.set('n', '<leader>ss', start_slime_session)
vim.keymap.set('n', '<leader>ip', start_ipython_session)
