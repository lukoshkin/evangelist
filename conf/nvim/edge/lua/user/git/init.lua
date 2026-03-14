return {
  {
    "NeogitOrg/neogit",
    keys = { { "<Leader>ng", ":Neogit<CR>" } },
    cmd = "Neogit",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "sindrets/diffview.nvim", -- optional - Diff integration
      "nvim-telescope/telescope.nvim", -- optional (fzf)
    },
    config = true,
  },
}
