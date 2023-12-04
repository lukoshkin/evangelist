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
        "pyright",
        "clangd",
        "lua_ls",
        "dockerls",
        "docker_compose_language_service",
      },
    },
    dependencies = "williamboman/mason.nvim",
  },
  {
    "jay-babu/mason-null-ls.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "nvimtools/none-ls.nvim",
    },
    opts = {
      automatic_installation = true,
      ensure_installed = {
        "shellcheck",
        "shfmt",
        "flake8",
        "pylint",
        "black",
        "cpplint",
        "rust-analyzer",
        -- "rustfmt", -- should be installed with rustup
        "stylua",
        "dockerfile-language-server",
        "cmake-language-server",
        "markdownlint",
      },
    },
  },

  --- CORE
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
  "lukoshkin/highlight-whitespace",
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
      vim.g.vimtex_compiler_progname = "nvr"
      vim.g.tex_flavor = "xelatex"
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
      keys = "ga",
      config = function()
        require "user.plugins.vim-easy-align"
      end,
    },
  },
  {
    "numToStr/Comment.nvim",
    keys = { { "gc", mode = "" } },
    config = true,
  },
  {
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    build = function()
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
    "github/copilot.vim", -- Do not load on InsertEnter (low UX)
    ft = { "python", "cpp", "c", "rust", "lua" },
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
    "neovim/nvim-lspconfig",
    dependencies = {
      "folke/lsp-colors.nvim",
      "weilbith/nvim-code-action-menu",
      "nvimtools/none-ls.nvim",
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
      {
        "tzachar/cmp-tabnine",
        build = "./install.sh",
      },
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

        ignore_lsp = { "null-ls" },

        -- manual_mode = true,
        -- silent_chdir = false, -- for debug
      }
    end,
  },
  {
    "rxi/json.lua",
    build = "mkdir -p lua/json && mv json.lua lua/json/init.lua",
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
