return {
  "echasnovski/mini.nvim",
  version = "*",
  event = "VeryLazy",
  config = function()
    require("mini.ai").setup()
    require("mini.surround").setup {
      mappings = {
        add = "ys",
        delete = "ds",
        replace = "cs",
      },
    }
    require("mini.operators").setup {
      -- 'gx' to swap two sequential selections
      -- 'g=' to evaluate (lime math expressions)
      -- 'gs' to sort (lexicographically or numerically)
      -- 'gr' prefix is already in use by default Vim LSP functionality
      replace = { prefix = "<Space>gr" },
    }
    require("mini.bracketed").setup {
      comment = { suffix = "/" },
    }
  end,
}
