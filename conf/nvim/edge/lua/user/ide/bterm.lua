return {
  "lukoshkin/bterm-repl.nvim",
  event = "VeryLazy",
  dependencies = "lukoshkin/bterm.nvim",
  config = function()
    require("bottom-term").setup()
    require("bottom-term-repl").setup()
  end,
}
