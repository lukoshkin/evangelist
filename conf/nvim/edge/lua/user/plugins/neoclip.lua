local yank_min_length = vim.g.neoclip_min_length or 3

require'neoclip'.setup {
  history = 20,
  --- Uncommenting requires glibc_2.29 and sqlite installed.
  -- enable_persistent_history = true,
  -- length_limit = 10000,

  filter = function (_)
    local last_yank = vim.fn.getreg('"')
    last_yank = last_yank:match "^%s*(.-)%s*$"
    return #last_yank > yank_min_length
  end,

  keys = {
    telescope = {
      i = {
        paste_behind = '<C-P>',
      },
      n = {
        --- Make sure that p and P mappings are not
        --- overwritten by some plugin like 'vim-pasta'.
        paste = {'p', '<C-p>'},
        paste_behind = {'P', '<C-P>'},
      },
    },
  },
}
