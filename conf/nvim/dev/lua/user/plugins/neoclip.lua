vim.g.neoclip_min_length = 3

require'neoclip'.setup {
  history = 20,
  --- Uncommenting requires glibc_2.29 and sqlite installed.
  -- enable_persistent_history = true,
  -- length_limit = 10000,

  filter = function (_)
    local last_yank = vim.fn.getreg('"')
    last_yank = last_yank:match "^%s*(.-)%s*$"
    return vim.fn.strlen(last_yank) > vim.g.neoclip_min_length
  end,

  keys = {
    telescope = {
      i = {
        paste = '<C-p>',
        paste_behind = '<C-P>',
      },
    },
  },
}
