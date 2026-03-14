local function on_attach(bufnr)
  local function opts(desc)
    return {
      desc = "nvim-tree: " .. desc,
      buffer = bufnr,
      noremap = true,
      silent = true,
      nowait = true,
    }
  end

  local api = require "nvim-tree.api"
  -- Default mappings
  api.config.mappings.default_on_attach(bufnr)

  -- Custom mappings
  local keymap = vim.keymap.set
  keymap(
    "n",
    "<C-s>",
    api.node.open.horizontal,
    opts "Open: In a Horizontal Split"
  )
  keymap(
    "n",
    "<A-v>",
    api.node.open.vertical,
    opts "Open: In a Vertical Split"
  )
  keymap("n", "t", api.node.open.tab, opts "Open: In a New Tab")
  keymap("n", "go", api.node.open.preview, opts "Open: Preview")
  keymap("n", "?", api.tree.toggle_help, opts "Help")
  keymap("n", "r", api.tree.reload, opts "Refresh")
  keymap("n", "R", api.fs.rename, opts "Rename")
  keymap(
    "n",
    "I",
    api.tree.toggle_gitignore_filter,
    opts "Toggle Git Ignore"
  )
  keymap("n", "d", api.fs.trash, opts "Trash")
  keymap("n", "D", api.fs.remove, opts "Delete")
end

return {
  "nvim-tree/nvim-tree.lua",
  --- Disable netrw at the very start of your init.lua
  init = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end,
  dependencies = "nvim-tree/nvim-web-devicons",
  keys = {
    { "<Leader>nt", ":NvimTreeToggle<CR>", desc = "Toggle NvimTree" },
    {
      "<Leader>nf",
      ":NvimTreeFindFileToggle<CR>",
      desc = "Find file in NvimTree",
    },
  },
  config = function()
    require("nvim-tree").setup {
      on_attach = on_attach,
      hijack_netrw = true,
      update_focused_file = {
        enable = true,
        update_cwd = true,
        ignore_list = {},
      },
      renderer = {
        highlight_opened_files = "icon",
        highlight_diagnostics = true,
        highlight_git = true,
        group_empty = true,
      },
    }

    local api = vim.api
    local fn = vim.fn
    local aug_ntc =
      vim.api.nvim_create_augroup("NvimTree-User", { clear = true })

    vim.api.nvim_create_autocmd("QuitPre", {
      callback = function()
        local force = false
        local name = api.nvim_buf_get_name(0)
        local stem = vim.fs.basename(name)
        local tnr = api.nvim_get_current_tabpage()
        if fn.winnr "$" == 1 and stem == "NvimTree_" .. tnr then
          local ok, _ = pcall(api.nvim_win_close, 0, force)
          if not ok then
            vim.cmd "quit"
          end
        end
      end,
      group = aug_ntc,
    })
  end,
}
