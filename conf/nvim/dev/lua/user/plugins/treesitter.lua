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
  context_commentstring = {
    enable = true,
  },
  textobjects = {
    select = {
      enable = true,
      -- Automatically jump forward to textobj, similar to targets.vim
      lookahead = true,
      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
      },
    },
  },
}

-- vim.opt.foldmethod = 'expr'
-- vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
