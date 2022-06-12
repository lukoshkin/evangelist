local keymap = require'lib.utils'.keymap

keymap('n', ']b', ':BufferLineCycleNext<CR>', {silent=true})
keymap('n', '[b', ':BufferLineCyclePrev<CR>', {silent=true})

require'bufferline'.setup ()
