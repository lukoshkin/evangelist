local keymap = require'lib.utils'.keymap


require'gitsigns'.setup {
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns

    keymap('n', ']g', function()
      if vim.wo.diff then return ']g' end
      vim.schedule(function() gs.next_hunk() end)
      return '<Ignore>'
    end, { expr = true })

    keymap('n', '[g', function()
      if vim.wo.diff then return '[g' end
      vim.schedule(function() gs.prev_hunk() end)
      return '<Ignore>'
    end, { expr = true })

    keymap('n', '<leader>hs', gs.stage_hunk)
    keymap('n', '<leader>hr', gs.reset_hunk)
    keymap('n', '<leader>hS', gs.stage_buffer)
    keymap('n', '<leader>hh', gs.preview_hunk)

    keymap('v', '<leader>hs', function()
      gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') }
    end)
    keymap('v', '<leader>hr', function()
      gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') }
    end)

    -- Text object
    keymap({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
  end
}
