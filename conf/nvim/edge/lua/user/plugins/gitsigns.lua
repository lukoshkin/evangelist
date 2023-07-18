local keymap = require'lib.utils'.keymap


require'gitsigns'.setup {
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns

    keymap('n', ']g', function()
      if vim.wo.diff then return ']g' end
      vim.schedule(function() gs.next_hunk() end)
      return '<Ignore>'
    end, {expr=true})

    keymap('n', '[g', function()
      if vim.wo.diff then return '[g' end
      vim.schedule(function() gs.prev_hunk() end)
      return '<Ignore>'
    end, {expr=true})

    keymap({'n', 'v'}, '<Leader>hr', ':Gitsigns reset_hunk<CR>')
  end
}
