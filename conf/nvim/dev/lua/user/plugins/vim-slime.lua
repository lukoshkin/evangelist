local keymap = require'lib.utils'.keymap

vim.g.slime_target = 'neovim'
vim.g.slime_dont_ask_default = 1
vim.g.slime_cell_delimiter = '#%%'

--- To send just a line, use <C-c><C-c> (default mapping).
--- Send text delimited by #%% (emulation of cells) with <C-s>.
keymap('n', '<leader><CR>', '<Plug>SlimeSendCell')
--- NOTE: <Plug>(SlimeSendCell) won't work here.

local function start_slime_session (cmd)
  local tab_var = vim.api.nvim_tabpage_get_var
  local tnr = vim.api.nvim_tabpage_get_number(0)

  if vim.fn.bufnr('BottomTerm') < 0
      or vim.fn.bufwinid('BottomTerm') < 0 then
    --- Why don't use `vim.fn.BottomTerm(cmd)`?
    --- Since it first executes the command, and then `conda_autoenv`
    --- switches to an appropriate environment. Before changing the
    --- environment, the command may be invalid or irrelevant.
    --- However, we can get back to `vim.fn.BottomTerm(cmd)` when
    --- functionality like `conda_autoenv` is added to Neovim settings.
    vim.fn.BottomtermToggle()
    --- `conda_autoenv` is available only after installing the Bash
    --- or Zsh settings and works in cooperation with project.nvim plugin.
  end

  --- NOTE: BottomtermToggle restores focus on a window from
  --- which it was called if 'bottom_term_focus_on_win' is true.
  --- Thus, the first next line is necessary.
  vim.fn.win_gotoid(vim.fn.bufwinid('BottomTerm'))
  local tji = vim.api.nvim_buf_get_var(0, 'terminal_job_id')
  vim.fn.chansend(tji, cmd .. "\n")

  if tab_var(tnr, 'bottom_term_horizontal') then
    vim.fn.BottomtermOrientation()
  end

  vim.g.slime_default_config = {
    jobid = tab_var(tnr, 'bottom_term_channel'),
    target_pane = '{top-right}',
  }
end

local function start_ipython_session ()
  local cwid = vim.fn.win_getid()
  local check = 'pip3 --disable-pip-version-check list 2>&1'
  check = check .. [[ | grep -qP 'matplotlib(?!-inline)' ]]

  local cmd = 'ipython'
  if os.execute(check) == 0 then
    cmd = cmd .. ' --matplotlib'
  end

  vim.g.bottom_term_focus_on_win = false
  start_slime_session(cmd)
  vim.g.bottom_term_focus_on_win = true

  vim.fn.win_gotoid(cwid)
  vim.cmd 'stopinsert'
end

--- TODO: Set local to buffer mappings.
keymap('n', '<leader>ss', start_slime_session)
keymap('n', '<leader>ip', start_ipython_session)
