local M = {}

M.keymap = vim.keymap.set

-- M.keymap = function(mode, lhs, rhs, opts)
--   vim.api.nvim_set_keymap(
--     mode,
--     lhs,
--     rhs,
--     vim.tbl_extend('keep', opts or {}, { noremap = true, silent = true })
--   )
-- end

M.buf_keymap = function(bufnr, mode, lhs, rhs, opts)
  vim.api.nvim_buf_set_keymap(
    bufnr,
    mode,
    lhs,
    rhs,
    vim.tbl_extend('keep', opts or {}, { noremap = true, silent = true })
  )
end


function M.shellcmd_capture(cmd, raw)
  --- 'r' is the default mode.
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()

  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end


local system = M.shellcmd_capture('uname')

if system == 'Linux' then
  M._opener = 'xdg-open'
elseif system == 'Darwin' then
  M._opener = 'open'
else
  --- presumably on Windows.
  --- 'start some.exe' - do we go like this?
  M._opener = 'start'
end

return M
