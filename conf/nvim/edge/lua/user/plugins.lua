local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
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
        -- "pyright",
        -- "basedpyright",
        "lua_ls",
        "marksman",
        "clangd",
        "dockerls",
        "docker_compose_language_service",
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
        "python-lsp-server",
        "shellcheck",
        "flake8",
        "pylint",
        "cpplint",
        "hadolint",
        "markdownlint",
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
  "LunarVim/bigfile.nvim",
  {
    "anuvyklack/hydra.nvim",
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
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-telescope/telescope-live-grep-args.nvim",
      "ahmedkhalf/project.nvim",
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
    "lukoshkin/tidy.nvim",
    dependencies = "neovim/nvim-lspconfig",
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
  {
    "nvim-lualine/lualine.nvim",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require "user.plugins.lualine"
    end,
  },
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
      "tpope/vim-surround",
      keys = { "ys", "cs", "ds" },
    },
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
  {
    "github/copilot.vim", -- Do not load on InsertEnter (low UX)
    --- Exclude `sh` file to prevent Copilot accessing '.env' files
    ft = { "python", "rust", "javascript", "lua", "bash", "cpp", "c" },
    config = function()
      require "user.plugins.copilot"
    end,
  },
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
    "neovim/nvim-lspconfig",
    dependencies = {
      "folke/lsp-colors.nvim",
      "SmiteshP/nvim-navic",
    },
    config = function()
      require "user.plugins.lspconfig"
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
  {
    "ahmedkhalf/project.nvim",
    config = function()
      require("project_nvim").setup {
        --- use pattern. If it doesn't find anything, use lsp.
        --- https://github.com/ahmedkhalf/project.nvim/issues/67
        -- detection_methods = { 'pattern', 'lsp' },

        -- manual_mode = true,
        -- silent_chdir = false, -- for debug
      }
    end,
  },
  {
    "rxi/json.lua",
    build = function()
      local build_dir = vim.fn.stdpath "data" .. "/lazy/json.lua/"
      local json_lua = build_dir .. "lua/json/"
      os.execute("mkdir -p " .. json_lua)
      os.execute("cp " .. build_dir .. "json.lua " .. json_lua .. "init.lua")
    end,
  },
  {
    "lukoshkin/auenv.nvim",
    ft = "python",
    dependencies = "rxi/json.lua",
    config = function()
      if vim.env.CONDA_PREFIX ~= nil then
        require("auenv").setup()
      end
    end,
  },
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
