local aug_cc = vim.api.nvim_create_augroup('CustomColors', {clear=true})

vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function ()
    vim.api.nvim_set_hl(0, 'SpellBad', {
      fg = 'NONE', bg = 'NONE', undercurl = true, sp = 'PaleVioletRed',
    })
    vim.api.nvim_set_hl(0, 'SpellCap', {
      fg = 'NONE', bg = 'NONE', undercurl = true, sp = 'Khaki1',
    })
    vim.api.nvim_set_hl(0, 'SpellRare', {
      fg = 'NONE', bg = 'NONE', undercurl = true, sp = 'MediumPurple1',
    })
    vim.api.nvim_set_hl(0, 'SpellLocal', {
      fg = 'NONE', bg = 'NONE', undercurl = true, sp = 'SkyBlue1',
    })
    vim.api.nvim_set_hl(0, 'CursorLineNr', {
      fg='gold3', bold=true,
    })
  end,
  group = aug_cc
})

require'nightfox'.setup{
  options = {
    styles = {
      comments = "italic",
      -- variables = "NONE",
      -- keywords = "NONE",
      types = "italic, bold",
      strings = "italic",
      -- functions = "NONE",
    }
  }
}

vim.cmd.colorscheme 'nordfox'
--- Also, a good colorscheme:
-- vim.cmd.colorscheme 'terafox'
