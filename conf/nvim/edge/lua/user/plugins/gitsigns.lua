local keymap = require("lib.utils").keymap
local api = vim.api

local function focused_move(move)
  return function()
    local prev_line = api.nvim_get_current_line()
    move()

    if api.nvim_get_current_line() ~= prev_line then
      --- Needs to be executed with a delay.
      --- Otherwise, not working in version 0.6
      vim.defer_fn(function()
        api.nvim_feedkeys("zz", "n", false)
      end, 5)
    end
  end
end

require("gitsigns").setup {
  on_attach = function(_bufnr)
    local gs = package.loaded.gitsigns
    keymap("n", "]g", function()
      if vim.wo.diff then
        return "]g"
      end
      vim.schedule(focused_move(gs.next_hunk))
      return "<Ignore>"
    end, { expr = true })

    keymap("n", "[g", function()
      if vim.wo.diff then
        return "[g"
      end
      vim.schedule(focused_move(gs.prev_hunk))
      return "<Ignore>"
    end, { expr = true })

    keymap("n", "<leader>hs", gs.stage_hunk)
    keymap("n", "<leader>hr", gs.reset_hunk)
    keymap("n", "<leader>hS", gs.stage_buffer)
    keymap('n', '<leader>hR', gs.reset_buffer)
    keymap("n", "<leader>hh", gs.preview_hunk)

    keymap("v", "<leader>hs", function()
      gs.stage_hunk { vim.fn.line ".", vim.fn.line "v" }
    end)
    keymap("v", "<leader>hr", function()
      gs.reset_hunk { vim.fn.line ".", vim.fn.line "v" }
    end)

    -- Text object
    keymap({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>")
  end,
}
