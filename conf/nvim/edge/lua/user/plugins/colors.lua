local aug_cc = vim.api.nvim_create_augroup("CustomColors", { clear = true })

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "SpellBad", {
      fg = nil,
      bg = nil,
      undercurl = true,
      sp = "PaleVioletRed",
    })
    vim.api.nvim_set_hl(0, "SpellCap", {
      fg = nil,
      bg = nil,
      undercurl = true,
      sp = "Khaki1",
    })
    vim.api.nvim_set_hl(0, "SpellRare", {
      fg = nil,
      bg = nil,
      undercurl = true,
      sp = "MediumPurple1",
    })
    vim.api.nvim_set_hl(0, "SpellLocal", {
      fg = nil,
      bg = nil,
      undercurl = true,
      sp = "SkyBlue1",
    })
    vim.api.nvim_set_hl(0, "CursorLineNr", {
      fg = "gold3",
      bold = true,
    })
    vim.api.nvim_set_hl(0, "CursorLine", {
      fg = nil,
      bg = "#3E4A5B",
    })
    vim.api.nvim_set_hl(0, "Visual", {
      fg = nil,
      bg = "#515151",
      bold = true,
    })
    vim.opt.guicursor = {
      "n-v-c-sm:block-Cursor",
      "i-ci-ve:ver25",
      "r-cr-o:hor20",
    }
    vim.api.nvim_set_hl(0, "Cursor", {
      fg = nil,
      bg = "gray14",
    })
  end,
  group = aug_cc,
})

require("nightfox").setup {
  options = {
    styles = {
      comments = "italic",
      -- variables = nil,
      -- keywords = nil,
      types = "italic, bold",
      strings = "italic",
      -- functions = nil,
    },
  },
}

vim.cmd.colorscheme "nordfox"
--- Also, a good colorscheme:
-- vim.cmd.colorscheme "terafox"
