return {
  "zbirenbaum/copilot.lua",
  event = "VeryLazy",
  keys = {
    {
      "<Space>ca",
      function()
        require("copilot.suggestion").toggle_auto_trigger()
      end,
      desc = "Toggle Copilot Auto-Suggestion",
    },
    {
      "<Space>cd",
      ":Copilot disable<CR>",
      desc = "Disable Copilot",
    },
    {
      "<Space>ce",
      ":Copilot enable<CR>",
      desc = "Enable Copilot",
    },
  },
  opts = {
    panel = {
      enabled = true,
      auto_refresh = false,
      keymap = {
        jump_prev = "[[",
        jump_next = "]]",
        accept = "<CR>",
        refresh = "<C-r>",
        open = "<M-CR>",
      },
      layout = {
        position = "bottom", -- | top | left | right | horizontal | vertical
        ratio = 0.4,
      },
    },
    suggestion = {
      enabled = true,
      auto_trigger = true,
      hide_during_completion = true,
      debounce = 500,
      trigger_on_accept = true,
      keymap = {
        accept = "<C-j>",
        accept_word = "<C-w>",
        accept_line = "<C-l>",
        next = "<C-n>", --- won't work when completion menu is visible
        prev = "<C-p>", --- won't work when completion menu is visible
        dismiss = "<C-e>",
      },
    },
    filetypes = {
      python = true,
      rust = true,
      yaml = true,
      markdown = true,
      gitcommit = true,
      sh = function() -- disable for .env files
        if
          string.match(
            vim.fs.basename(vim.api.nvim_buf_get_name(0)),
            "^%.env.*"
          )
        then
          return false
        end
        return true
      end,
      zsh = function()
        local filename = vim.fs.basename(vim.api.nvim_buf_get_name(0))
        if
          filename == ".zshrc"
          or filename == ".zprofile"
          or filename == "custom.zsh"
        then
          return false
        end
        return true
      end,
      help = false,
      gitrebase = false,
      confini = false,
      ["*"] = true,
    },
    auth_provider_url = nil, -- URL to authentication provider, if not "https://github.com/"
    logger = {
      file = vim.fn.stdpath "log" .. "/copilot-lua.log",
      file_log_level = vim.log.levels.OFF,
      print_log_level = vim.log.levels.WARN,
      trace_lsp = "off", -- "off" | "messages" | "verbose"
      trace_lsp_progress = false,
      log_lsp_messages = false,
    },
    copilot_node_command = "node", -- Node.js version must be > 20
    workspace_folders = {},
    copilot_model = "", -- Current LSP default is gpt-35-turbo, supports gpt-4o-copilot
    root_dir = function()
      return vim.fs.dirname(vim.fs.find(".git", { upward = true })[1])
    end,
    --- More granular than `filetypes` control of when to attach the Copilot
    should_attach = function(_, _)
      if not vim.bo.buflisted then
        return false
      end

      if vim.bo.buftype ~= "" then
        return false
      end

      if
        string.match(vim.fs.basename(vim.api.nvim_buf_get_name(0)), "secret")
        or string.match(
          vim.fs.basename(vim.api.nvim_buf_get_name(0)),
          "%f[%a]credentials%f[^%a]"
        )
        or string.match(
          vim.fs.basename(vim.api.nvim_buf_get_name(0)),
          "%f[%a]creds%f[^%a]"
        )
      then
        return false
      end

      return true
    end,
    server = {
      type = "nodejs", -- "nodejs" | "binary"
      custom_server_filepath = nil,
    },
    server_opts_overrides = {},
  },
}
