return {
  "yetone/avante.nvim",
  -- version = "0.0.27",
  version = false, -- nightly build
  event = "VeryLazy",
  init = function()
    vim.g.root_spec = { { ".git" }, "lsp", "cwd" }
    vim.opt.laststatus = 3
  end,
  keys = {
    {
      "<Space>am",
      function()
        vim.cmd "normal :"
        local start_line = vim.fn.line "'<"
        local end_line = vim.fn.line "'>"
        if start_line == end_line then
          vim.cmd(
            ":'<,'>AvanteEdit Make it multiline: fit each new line into 79"
              .. " char line-length limitation. Move the space from the end of"
              .. " the line to the beginning of the next line<CR>"
          )
          return
        end
        vim.cmd(
          ":'<,'>AvanteEdit Rewrite the multiline string: make long lines"
            .. " shorter, and to short ones longer. Splits should be done"
            .. " on a char **BEFORE** space after which goes punctuation or"
            .. " a new word<CR>"
        )
      end,
      mode = "v",
    },
    {
      "<Space>at",
      ":AvanteEdit make it ternary operator<CR>",
      mode = "v",
    },
    {
      "<C-w>",
      "<Esc><C-w>",
      mode = "i",
      desc = "Exit insert mode in AvanteInput and embrace for a jump",
      ft = "AvanteInput",
    },
    {
      "<Space>a=",
      function()
        local tree_ext = require "avante.extensions.nvim_tree"
        tree_ext.add_file()
      end,
      desc = "Select file in NvimTree",
      ft = "NvimTree",
    },
    {
      "<Space>a-",
      function()
        local tree_ext = require "avante.extensions.nvim_tree"
        tree_ext.remove_file()
      end,
      desc = "Deselect file in NvimTree",
      ft = "NvimTree",
    },
  },
  opts = {
    system_prompt = function()
      local hub = require("mcphub").get_hub_instance()
      local mcp_prompts = hub and hub:get_active_servers_prompt() or ""

      local file_path = os.getenv "EVANGELIST"
        .. "/conf/nvim/edge/supplement.avanterules"
      local file = io.open(file_path, "r")
      local custom_prompt = ""
      if file then
        custom_prompt = file:read "*all"
        file:close()
      else
        vim.notify(
          "File not found: " .. file_path,
          vim.log.levels.WARN,
          { title = "Avante" }
        )
      end

      return table.concat(
        vim.tbl_filter(function(s)
          return s ~= nil and s ~= ""
        end, { mcp_prompts, custom_prompt }),
        "\n\n"
      )
    end,
    selector = { exclude_auto_select = { "NvimTree" } },
    ---@alias avante.ProviderName "claude" | "openai" | "azure" | "gemini" | "vertex" | "cohere" | "copilot" | "bedrock" | "ollama" | string
    --- WARNING: Since auto-suggestions are a high-frequency operation and
    --- therefore expensive, currently designating it as `copilot` provider is
    --- dangerous because: https://github.com/yetone/avante.nvim/issues/1048 Of
    --- course, you can reduce the request frequency by increasing
    --- `suggestion.debounce` time.
    provider = "copilot",
    auto_suggestions_provider = "copilot", -- use Copilot and Avante separately
    cursor_applying_provider = nil, -- The provider used in the applying phase
    -- of Cursor Planning Mode. Defaults to nil. When nil, uses Config.provider
    -- as the provider for the applying phase
    web_search_engine = {
      provider = "tavily",
      proxy = nil,
      providers = {
        tavily = {
          api_key_name = "TAVILY_API_KEY",
          extra_request_body = {
            include_answer = "basic",
          },
          ---@type WebSearchEngineProviderResponseBodyFormatter
          format_response_body = function(body)
            return body.answer, nil
          end,
        },
      },
    },
    rag_service = {
      enabled = false,
      host_mount = vim.fn.getcwd(),
      -- host_mount = os.getenv "HOME" .. "/Workspace",
      runner = "docker",
      llm = {
        provider = "openai",
        endpoint = "https://api.openai.com/v1",
        model = "gpt-4o-mini",
        extra = nil,
      },
      embed = {
        provider = "openai",
        endpoint = "https://api.openai.com/v1",
        model = "text-embedding-3-large",
        extra = nil,
      },
      docker_extra_args = "", -- Extra arguments to pass to the docker command
    },
    custom_tools = function()
      return { require("mcphub.extensions.avante").mcp_tool() }
    end,
    behaviour = {
      auto_suggestions = false, -- Experimental stage
      auto_set_highlight_group = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
      support_paste_from_clipboard = false,
      minimize_diff = true, -- Whether to remove unchanged lines when applying a code block
      enable_token_counting = true, -- Whether to enable token counting. Default to true.
      enable_cursor_planning_mode = false, -- Whether to enable Cursor Planning Mode. Default to false.
    },
    mappings = {
      --- @class AvanteConflictMappings
      diff = {
        ours = "co",
        theirs = "ct",
        all_theirs = "ca",
        both = "cb",
        cursor = "cc",
        next = "]x",
        prev = "[x",
      },
      suggestion = {
        accept = "<C-j>",
        next = "<M-]>",
        prev = "<M-[>",
        dismiss = "<C-e>",
      },
      jump = {
        next = "]]",
        prev = "[[",
      },
      submit = {
        normal = "<CR>",
        insert = "<C-s>",
      },
      cancel = {
        normal = { "<C-c>" },
        insert = { "<C-c>" },
      },
      sidebar = {
        apply_all = "A",
        apply_cursor = "a",
        retry_user_request = "r",
        edit_user_request = "e",
        switch_windows = "<Tab>",
        reverse_switch_windows = "<S-Tab>",
        remove_file = "d",
        add_file = "a",
        close = { "q" },
        close_from_input = { normal = "q", insert = "<C-d>" },
      },
    },
    -- disabled_tools = {  -- Can be disabled in favor of MCP Neovim server
    --   "bash",
    --   "glob",
    --   "read_file", -- likely is outdated name
    --   "move_path", -- likely is outdated name
    --   "delete_path", -- likely is outdated name
    --   "replace_in_file",
    --   "write_to_file",
    -- },
    hints = { enabled = true },
    windows = {
      ---@type "right" | "left" | "top" | "bottom"
      position = "right", -- the position of the sidebar
      wrap = true, -- similar to vim.o.wrap
      width = 35, -- default % based on available width
      sidebar_header = {
        enabled = true, -- true, false to enable/disable the header
        align = "center", -- left, center, right for title
        rounded = true,
      },
      input = {
        provider = "snacks",
        prefix = "> ",
        height = 8, -- Height of the input window in vertical layout
      },
      edit = {
        border = "rounded",
        start_insert = true, -- Start insert mode when opening the edit window
      },
      ask = {
        floating = false, -- Open the 'AvanteAsk' prompt in a floating window
        start_insert = true, -- Start insert mode when opening the ask window
        border = "rounded",
        ---@type "ours" | "theirs"
        focus_on_apply = "ours", -- which diff to focus after applying
      },
    },
    highlights = {
      ---@type AvanteConflictHighlights
      diff = {
        current = "DiffText",
        incoming = "DiffAdd",
      },
    },
    --- @class AvanteConflictUserConfig
    diff = {
      autojump = true,
      ---@type string | fun(): any
      list_opener = "copen",
      --- Override the 'timeoutlen' setting while hovering over a diff (see :help timeoutlen).
      --- Helps to avoid entering operator-pending mode with diff mappings starting with `c`.
      --- Disable by setting to -1.
      override_timeoutlen = 500,
    },
    suggestion = {
      debounce = 1000, -- in case, auto-suggestions are enabled
      throttle = 1000,
    },
  },
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  build = "make",
  dependencies = {
    "ravitemer/mcphub.nvim",
    "nvim-treesitter/nvim-treesitter",
    "folke/snacks.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    "echasnovski/mini.pick", -- for file_selector provider mini.pick
    "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
    "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
    "ibhagwan/fzf-lua", -- for file_selector provider fzf
    "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    "zbirenbaum/copilot.lua", -- for providers='copilot'
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = { insert_mode = true },
          use_absolute_path = true, -- required for Windows users
        },
      },
    },
    {
      "OXY2DEV/markview.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
        html = { enable = true },
        latex = { enable = true },
        preview = {
          enable = true,
          hybrid_modes = { "n" },
          max_buf_lines = 100,
        },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
