local keymap = require'lib.utils'.keymap

if vim.fn.has('python3') then
  keymap('n', '<Leader>u', ':MundoToggle<CR>')
end
