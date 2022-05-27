require'bufferline'.setup ()

vim.keymap.set('n', ']b', ':BufferLineCycleNext<CR>', {silent=true})
vim.keymap.set('n', '[b', ':BufferLineCyclePrev<CR>', {silent=true})
