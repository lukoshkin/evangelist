return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      input = {
        keys = {
          n_esc = {
            "<esc>",
            { "cmp_close", "cancel" },
            mode = "n",
            expr = true,
          },
          i_esc = {
            "<esc>",
            { "cmp_close", "stopinsert" },
            mode = "i",
            expr = true,
          },
          i_cr = {
            "<cr>",
            { "cmp_accept", "confirm" },
            mode = { "i", "n" },
            expr = true,
          },
          i_tab = {
            "<tab>",
            { "cmp_select_next", "cmp" },
            mode = "i",
            expr = true,
          },
          i_ctrl_w = { "<c-w>", "<c-s-w>", mode = "i", expr = true },
          i_up = { "<up>", { "hist_up" }, mode = { "i", "n" } },
          i_down = { "<down>", { "hist_down" }, mode = { "i", "n" } },
          q = "cancel",
        },
      },
      bigfile = {
        enabled = false,
        notify = true,
        size = 1.5 * 1024 * 1024,
        line_length = 1000,
        ---@param ctx {buf: number, ft:string}
        setup = function(ctx)
          if vim.fn.exists ":NoMatchParen" ~= 0 then
            vim.cmd [[NoMatchParen]]
          end
          require("snacks").util.wo(
            0,
            { foldmethod = "manual", statuscolumn = "", conceallevel = 0 }
          )
          vim.b.minianimate_disable = true
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(ctx.buf) then
              vim.bo[ctx.buf].syntax = ctx.ft
            end
          end)
        end,
      },
    },
  },
  { "pteroctopus/faster.nvim" },
  "tpope/vim-sleuth",
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    build = "./kitty/install-kittens.bash",
    keys = {
      { "<C-w><C-j>", function() require("smart-splits").move_cursor_down() end },
      { "<C-w><C-k>", function() require("smart-splits").move_cursor_up() end },
      { "<C-w><C-h>", function() require("smart-splits").move_cursor_left() end },
      { "<C-w><C-l>", function() require("smart-splits").move_cursor_right() end },
    },
  },
}
