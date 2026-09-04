return {
  "akinsho/bufferline.nvim",
  event = "BufRead",
  cond = not vim.g.nvim_minimal,
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function()
    -- keymap('n', ']b', ':BufferLineCycleNext<CR>', {silent=true})
    -- keymap('n', '[b', ':BufferLineCyclePrev<CR>', {silent=true})
    --- No longer needed, as we have 'mini.bracketed' for this.
    require("bufferline").setup()
  end,
}
