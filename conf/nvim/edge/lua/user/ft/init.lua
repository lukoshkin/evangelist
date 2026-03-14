return {
  {
    "lervag/vimtex",
    ft = "tex",
    -- for some reason, `config = true` does not work
    init = function() end,
  },
  {
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    build = function()
      vim.opt.rtp:prepend(
        vim.fn.stdpath "data" .. "/lazy/markdown-preview.nvim"
      )
      vim.fn["mkdp#util#install"]()
    end,
    config = function()
      local keymap = require("lib.utils").keymap

      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_refresh_slow = 1
      vim.g.mkdp_command_for_global = 0
      vim.g.mkdp_open_to_the_world = 0
      vim.g.mkdp_open_ip = ""
      vim.g.mkdp_browser = ""
      vim.g.mkdp_echo_preview_url = 0
      vim.g.mkdp_browserfunc = ""
      vim.g.mkdp_preview_options = {
        mkit = {},
        katex = {},
        uml = {},
        maid = {},
        disable_sync_scroll = 0,
        sync_scroll_type = "middle",
        hide_yaml_meta = 1,
        sequence_diagrams = {},
        flowchart_diagrams = {},
        content_editable = false,
        disable_filename = 0,
      }
      vim.g.mkdp_markdown_css = ""
      vim.g.mkdp_highlight_css = ""
      vim.g.mkdp_port = ""
      vim.g.mkdp_page_title = "${name}"

      keymap("n", "<Leader>md", "<Plug>MarkdownPreviewToggle")
    end,
  },
  {
    "kkoomen/vim-doge",
    build = ":call doge#install()",
    keys = { { "<LocalLeader>dg", ":DogeGenerate<CR>" } },
    ft = { "python", "rust", "bash", "lua", "cpp", "c" },
    init = function()
      vim.g.doge_doc_standard_python = "numpy"
      vim.g.doge_enable_mappings = false
    end,
  },
  {
    "lukoshkin/pymove.nvim",
    ft = "python",
    config = true,
  },
  --- Temporarily disable auenv.nvim since it is disruptive for the work
  --- of LSP clients: breaks ruff, pylsp, basedpyright, and similar
  -- {
  --   "lukoshkin/auenv.nvim",
  --   ft = "python",
  --   dependencies = "rxi/json.lua",
  --   config = function()
  --     if vim.env.CONDA_PREFIX ~= nil then
  --       require("auenv").setup()
  --     end
  --   end,
  -- },
}
