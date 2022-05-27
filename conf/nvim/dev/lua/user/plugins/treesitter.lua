require('nvim-treesitter.configs').setup {
  ensure_installed = {
    'c',
    'rust',
    'python',
    'bash',
    'vim',
    'lua',
    'dockerfile',
    'make',
    'cmake'
  },

  indent = {
    enable = true,
  },
  highlight = {
    enable = true,
    disable = { 'NvimTree' },
    additional_vim_regex_highlighting = true,
  },
  context_commentstring = {
    enable = true,
  },
}

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

-- vim.cmd [[
--   set foldmethod=expr
--   set foldexpr=nvim_treesitter#foldexpr()
-- ]]
