--- Not sure about this
require('ts_context_commentstring').setup {}
vim.g.skip_ts_context_commentstring_module = true

require'nvim-treesitter.configs'.setup {
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
    disable = { 'yaml', 'python' }
    --- Leaving treesitter indentation enabled for 'python' actually
    --- breaks the indentation instead of improving it.
  },
  highlight = {
    enable = true,
    disable = { 'NvimTree', 'latex' },
    additional_vim_regex_highlighting = true,
  },
  textobjects = {
    select = {
      enable = true,
      --- Automatically jump forward to textobj, similar to targets.vim
      lookahead = true,
      keymaps = {
        --- You can use the capture groups defined in textobjects.scm
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
        ['ab'] = '@block.outer',
        ['ib'] = '@block.inner',
        --- TODO: add mapping for python docstring selection.
      },
    },
  },
}

-- vim.opt.foldmethod = 'expr'
-- vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
