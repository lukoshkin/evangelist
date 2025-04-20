local keymap = require'lib.utils'.keymap

-- keymap('n', ']b', ':BufferLineCycleNext<CR>', {silent=true})
-- keymap('n', '[b', ':BufferLineCyclePrev<CR>', {silent=true})
--- No longer needed, as we have 'mini.bracketed' for this.

require'bufferline'.setup ()
