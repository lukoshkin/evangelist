return {
  "nvimtools/hydra.nvim",
  event = "VeryLazy",
  config = function()
    vim.defer_fn(function()
      local Hydra = require "hydra"

      --- Pink uses buffer-local keymaps (Layer) instead of the default
      --- red's <Plug> + feedkeys mechanism, which breaks on newer Neovim.
      local nowait = { nowait = true }

      Hydra {
        name = "diff mode (forward)",
        config = { color = "pink" },
        mode = "n",
        body = "]",
        heads = {
          { "c", "]c", nowait },
          { "p", "dp", nowait },
          { "o", "do", nowait },
          { "<Esc>", nil, { exit = true } },
        },
      }
      Hydra {
        name = "diff mode (backward)",
        config = { color = "pink" },
        mode = "n",
        body = "[",
        heads = {
          { "c", "[c", nowait },
          { "p", "dp", nowait },
          { "o", "do", nowait },
          { "<Esc>", nil, { exit = true } },
        },
      }
    end, 5)
  end,
}
