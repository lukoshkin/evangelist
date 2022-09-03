vim.g.nord_contrast = true
vim.g.nord_borders = true
vim.g.nord_italic = false

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
  end,
  group = aug_cc
})

vim.cmd 'colorscheme nord'
