return {
  {
    "numToStr/Comment.nvim",
    keys = { { "gc", mode = "" } },
    opts = { ignore = "^$" },
  },
  {
    "junegunn/vim-easy-align",
    keys = {
      { "ga", "<Plug>(EasyAlign)", mode = "x" },
      { "ga", "<Plug>(EasyAlign)", mode = "n" },
    },
  },
  {
    "ku1ik/vim-pasta",
    event = { "BufRead", "BufNewFile" },
    init = function()
      vim.g.pasta_disabled_filetypes = { "yaml", "markdown" }
    end,
  },
  {
    --- Go to file (but first, create if doesn't exist).
    "jessarcher/vim-heritage",
    keys = { { "gf", ":edit <cfile><CR>", mode = "" } },
    -- cmd = { "edit", "write" }, -- will not work
    event = "CmdlineEnter",
  },
  { "tpope/vim-eunuch", event = "CmdlineEnter" },
  { "farmergreg/vim-lastplace", event = "BufRead" },
  { "tpope/vim-repeat", event = "BufRead" },
  { "dstein64/vim-startuptime", cmd = "StartupTime" },
  {
    "mhinz/vim-sayonara",
    keys = { { "<Leader>q", ":Sayonara!<CR>" } },
  },
  {
    "lukoshkin/tidy.nvim",
    event = { "BufRead", "BufNewFile" },
    config = true,
  },
  {
    "AckslD/nvim-neoclip.lua",
    keys = "<Leader>fy",
    dependencies = "nvim-telescope/telescope.nvim",
    config = function()
      local yank_min_length = vim.g.neoclip_min_length or 3

      require("neoclip").setup {
        history = 20,
        --- Uncommenting requires glibc_2.29 and sqlite installed.
        -- enable_persistent_history = true,
        -- length_limit = 10000,
        filter = function(_)
          local last_yank = vim.fn.getreg '"'
          last_yank = last_yank:match "^%s*(.-)%s*$"
          return #last_yank > yank_min_length
        end,
        keys = {
          telescope = {
            i = { paste_behind = "<C-P>" },
            --- Make sure that p and P mappings are not
            --- overwritten by some plugin like 'vim-pasta'.
            n = {
              paste = { "p", "<C-p>" },
              paste_behind = { "P", "<C-P>" },
            },
          },
        },
      }
    end,
  },
}
