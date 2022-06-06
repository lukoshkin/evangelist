require'neoclip'.setup {
  history=20,
  --- Uncommenting requires glibc_2.29 and sqlite installed.
  -- enable_persistent_history = true,
  -- length_limit = 10000,

  keys = {
    telescope = {
      i = {
        paste = '<C-p>',
        paste_behind = '<C-P>',
      },
    },
  },
}
