return {
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "VeryLazy",
    config = true,
    main = "ibl",
  },
  {
    "lukoshkin/highlight-whitespace",
    event = { "BufRead", "BufNewFile" },
    config = true,
  },
  {
    "SmiteshP/nvim-navic",
    dependencies = "neovim/nvim-lspconfig",
    event = "LspAttach",
  },
  {
    "lukoshkin/unititle.nvim",
    event = "VeryLazy",
  },
  {
    "unblevable/quick-scope",
    keys = { "f", "F", "t", "T" },
    init = function()
      vim.g.qs_lazy_highlight = 1
      vim.g.qs_highlight_on_keys = { "f", "F", "t", "T" }
      vim.g.qs_filetype_blacklist = { "dashboard", "fidget" }

      local aug_qs =
        vim.api.nvim_create_augroup("QS_Colors", { clear = true })
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          vim.api.nvim_set_hl(0, "QuickScopePrimary", {
            underline = true,
            fg = "PaleVioletRed",
          })
          vim.api.nvim_set_hl(0, "QuickScopeSecondary", {
            undercurl = true,
            fg = "RosyBrown3",
          })
        end,
        group = aug_qs,
      })

      --- Possible extension: nmap toggle for highlighting support chars in both
      --- forward and backward directions and clearing highlights if the keystroke
      --- is pressed the second time on the same line.
    end,
  },
}
