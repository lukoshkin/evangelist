local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
local evn_path = vim.fn.getenv "EVANGELIST"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  }
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup {
  {
    "williamboman/mason.nvim",
    config = true,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      automatic_installation = true,
      ensure_installed = {
        "bashls",
        "basedpyright",
        "lua_ls",
        "marksman",
        "ruff",
        "clangd",
        "dockerls",
        "docker_compose_language_service",
        "yamlls",
      },
    },
    dependencies = "williamboman/mason.nvim",
  },
  {
    "rshkarin/mason-nvim-lint",
    dependencies = {
      "williamboman/mason.nvim",
      "mfussenegger/nvim-lint",
    },
    opts = {
      automatic_installation = true,
      ensure_installed = {
        "shellcheck",
        "cpplint",
        "hadolint",
        "markdownlint",
        "yamllint",
        "cspell",
      },
    },
  },
  {
    "zapling/mason-conform.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "stevearc/conform.nvim",
    },
    config = function()
      local mapping = require "mason-conform.mapping"

      local function auto_install()
        local config = require("mason-conform").config
        local formatters_by_ft = require("conform").formatters_by_ft

        local formatters_to_install = {}
        for _, formatters in pairs(formatters_by_ft) do
          if type(formatters) == "function" then
            formatters = formatters()
          end
          for _, formatter in pairs(formatters) do
            if type(formatter) == "table" then
              for _, f in pairs(formatter) do
                formatters_to_install[f] = 1
              end
            else
              formatters_to_install[formatter] = 1
            end
          end
        end

        for _, formatter_to_ignore in pairs(config.ignore_install) do
          formatters_to_install[formatter_to_ignore] = nil
        end

        for conformFormatter, _ in pairs(formatters_to_install) do
          local package = mapping.conform_to_package[conformFormatter]
          if package ~= nil then
            require("mason-conform.install").try_install(package)
          end
        end
      end

      local mason_conform = require "mason-conform"
      mason_conform.auto_install = auto_install
      mason_conform.auto_install()
    end,
  },

  --- CORE
  -- { "glacambre/firenvim", build = ":call firenvim#install(0)" },
  -- { require "user.plugins.noice" },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      input = {
        keys = {
          n_esc = {
            "<esc>",
            { "cmp_close", "cancel" },
            mode = "n",
            expr = true,
          },
          i_esc = {
            "<esc>",
            { "cmp_close", "stopinsert" },
            mode = "i",
            expr = true,
          },
          i_cr = {
            "<cr>",
            { "cmp_accept", "confirm" },
            mode = { "i", "n" },
            expr = true,
          },
          i_tab = {
            "<tab>",
            { "cmp_select_next", "cmp" },
            mode = "i",
            expr = true,
          },
          i_ctrl_w = { "<c-w>", "<c-s-w>", mode = "i", expr = true },
          i_up = { "<up>", { "hist_up" }, mode = { "i", "n" } },
          i_down = { "<down>", { "hist_down" }, mode = { "i", "n" } },
          q = "cancel",
        },
      },
      bigfile = {
        enabled = false,
        notify = true,
        size = 1.5 * 1024 * 1024, -- 1.5MB
        line_length = 1000, -- average line length (useful for minified files)
        -- Enable or disable features when big file detected
        ---@param ctx {buf: number, ft:string}
        setup = function(ctx)
          if vim.fn.exists ":NoMatchParen" ~= 0 then
            vim.cmd [[NoMatchParen]]
          end
          require("snacks").util.wo(
            0,
            { foldmethod = "manual", statuscolumn = "", conceallevel = 0 }
          )
          vim.b.minianimate_disable = true
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(ctx.buf) then
              vim.bo[ctx.buf].syntax = ctx.ft
            end
          end)
        end,
      },
    },
  },

  { require "user.plugins.avante" },
  {
    "pteroctopus/faster.nvim",
  },
  {
    "echasnovski/mini.nvim",
    version = "*",
    config = function()
      require "user.plugins.mini"
    end,
  },
  {
    "nvimtools/hydra.nvim",
    config = function()
      --- For some reason, a small delay should be introduced.
      vim.defer_fn(function()
        require "user.plugins.hydra"
      end, 5)
    end,
  },
  {
    "monaqa/dial.nvim",
    config = function()
      require "user.plugins.dial"
    end,
    keys = {
      {
        "<C-a>",
        function()
          require("dial.map").manipulate("increment", "normal")
        end,
        mode = "",
      },
      {
        "<C-x>",
        function()
          require("dial.map").manipulate("decrement", "normal")
        end,
        mode = "",
      },
    },
  },
  {
    "nvim-tree/nvim-tree.lua",
    -- Disable netrw at the very start of your init.lua
    init = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require "user.plugins.nvim-tree"
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "AckslD/nvim-neoclip.lua",
      "rcarriga/nvim-notify",
      "nvim-telescope/telescope-project.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-telescope/telescope-live-grep-args.nvim",
      "debugloop/telescope-undo.nvim",
    },
    config = function()
      require "user.plugins.telescope"
    end,
  },

  --- APPEARANCE
  {
    "lukoshkin/highlight-whitespace",
    config = true,
  },
  {
    "SmiteshP/nvim-navic",
    dependencies = { "neovim/nvim-lspconfig" },
  },
  {
    dir = evn_path .. "/pymove",
    config = true,
  },
  {
    "lukoshkin/tidy.nvim",
    config = true,
  },
  {
    "aznhe21/actions-preview.nvim",
    keys = {
      {
        "<Leader>ca",
        function()
          require("actions-preview").code_actions()
        end,
        mode = "",
      },
    },
    config = function()
      require("actions-preview").setup {
        telescope = {
          sorting_strategy = "ascending",
          layout_strategy = "vertical",
          layout_config = {
            width = 0.8,
            height = 0.9,
            prompt_position = "top",
            preview_cutoff = 20,
            preview_height = function(_, _, max_lines)
              return max_lines - 15
            end,
          },
        },
      }
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    config = true,
    main = "ibl",
  },
  "lukoshkin/unititle.nvim",
  {
    "EdenEast/nightfox.nvim",
    priority = 1000,
    config = function()
      require "user.plugins.colors"
    end,
  },
  {
    "akinsho/bufferline.nvim",
    event = "BufRead",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require "user.plugins.bufferline"
    end,
  },
  { require "user.plugins.lualine" },
  {
    "lewis6991/gitsigns.nvim",
    event = "BufRead",
    dependencies = "nvim-lua/plenary.nvim",
    config = function()
      require "user.plugins.gitsigns"
    end,
  },

  --- MISCELLANEA
  {
    "ku1ik/vim-pasta",
    init = function()
      vim.g.pasta_disabled_filetypes = {
        "yaml",
        "markdown",
      }
    end,
  },
  "tpope/vim-sleuth",
  { "tpope/vim-eunuch", event = "CmdlineEnter" },
  {
    --- Go to file (but first, create if doesn't exist).
    "jessarcher/vim-heritage",
    keys = { { "gf", ":edit <cfile><CR>", mode = "" } },
    -- cmd = { "edit", "write" }, -- will not work
    event = "CmdlineEnter",
  },
  {
    "rcarriga/nvim-notify",
    config = function()
      require "user.plugins.notify"
    end,
  },
  {
    "unblevable/quick-scope",
    keys = { "f", "F", "t", "T" },
    init = function()
      require "user.plugins.quick-scope"
    end,
  },
  {
    "mhinz/vim-sayonara",
    keys = { { "<Leader>q", ":Sayonara!<CR>" } },
  },
  {
    "lervag/vimtex",
    ft = "tex",
    init = function()
      -- for some reason, `config = true` does not work
    end,
  },
  {
    { "farmergreg/vim-lastplace", event = "BufRead" },
    { "tpope/vim-repeat", event = "BufRead" },
    { "dstein64/vim-startuptime", cmd = "StartupTime" },
    {
      "junegunn/vim-easy-align",
      keys = { { "ga", mode = "" } },
      config = function()
        require "user.plugins.vim-easy-align"
      end,
    },
  },
  {
    "numToStr/Comment.nvim",
    keys = { { "gc", mode = "" } },
    opts = { ignore = "^$" },
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
      require "user.plugins.md-preview"
    end,
  },
  {
    "AckslD/nvim-neoclip.lua",
    keys = "<Leader>fy",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require "user.plugins.neoclip"
    end,
  },

  --- IDE-LIKE
  { "neovim/nvim-lspconfig" },
  {
    "NeogitOrg/neogit",
    keys = { { "<Leader>ng", ":Neogit<CR>" } },
    cmd = "Neogit",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "sindrets/diffview.nvim", -- optional - Diff integration
      "nvim-telescope/telescope.nvim", -- optional (fzf)
    },
    config = true,
  },
  { require "user.plugins.mcp" },
  { require "user.plugins.copilot" },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate | :TSInstall! query",
    dependencies = {
      "nvim-treesitter/playground",
      "nvim-treesitter/nvim-treesitter-textobjects",
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    config = function()
      require "user.plugins.treesitter"
    end,
  },
  {
    "mfussenegger/nvim-lint",
    event = {
      "BufReadPre",
      "BufNewFile",
    },
    config = function()
      require "user.plugins.lint"
    end,
  },
  {
    "stevearc/conform.nvim",
    event = {
      "BufReadPre",
      "BufNewFile",
    },
    config = function()
      require "user.plugins.conform"
    end,
  },
  {
    "ray-x/lsp_signature.nvim",
    event = "VeryLazy",
    config = true,
  },
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "luvit-meta/library", words = { "vim%.uv" } },
      },
    },
  },
  { "Bilal2453/luvit-meta", lazy = true }, -- optional `vim.uv` typings
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "dmitmel/cmp-digraphs",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
      "L3MON4D3/LuaSnip",
      -- { -- obsolete, one can use https://github.com/codota/tabnine-nvim instead
      --   "tzachar/cmp-tabnine",
      --   build = "./install.sh",
      -- },
      "hrsh7th/cmp-nvim-lua",
      "onsails/lspkind-nvim",
    },
    config = function()
      require "user.plugins.cmp"
    end,
  },

  -- {
  --   'puremourning/vimspector',
  --   config = function ()
  --     require'user.plugins.vimspector'
  --   end
  -- },

  {
    "mfussenegger/nvim-dap",
    keys = { "<Leader>di", "<Space>.", "<Space>,", "<Space>;", "<Space>g" },
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "mfussenegger/nvim-dap-python",
      "nvim-telescope/telescope-dap.nvim",
    },
    config = function()
      require "user.plugins.dap"
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
  --- Temporarily disable auenv.nvim since it is disruptive for the work
  --- of LSP clients: breaks ruff, pylsp, basedpyright, and similar
  -- {
  --   "rxi/json.lua",
  --   build = function()
  --     local build_dir = vim.fn.stdpath "data" .. "/lazy/json.lua/"
  --     local json_lua = build_dir .. "lua/json/"
  --     os.execute("mkdir -p " .. json_lua)
  --     os.execute("cp " .. build_dir .. "json.lua " .. json_lua .. "init.lua")
  --   end,
  -- },
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
  {
    --- NOTE: Loading can be optimized with 'lazy'.
    "lukoshkin/bterm-repl.nvim",
    dependencies = "lukoshkin/bterm.nvim",
    config = function()
      require("bottom-term").setup()
      require("bottom-term-repl").setup()
    end,
  },
}
