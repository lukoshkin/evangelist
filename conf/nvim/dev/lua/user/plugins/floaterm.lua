local keymap = require'lib.utils'.keymap

keymap('n', '<A-t>', ':FloatermToggle scratch<CR>')
keymap('t', '<A-t>', '<C-\\><C-n>:FloatermToggle scratch<CR>')

vim.g.floaterm_opener = 'vsplit'
-- vim.g.floaterm_width = 0.8
-- vim.g.floaterm_height = 0.8
-- vim.g.floaterm_wintitle = 0
