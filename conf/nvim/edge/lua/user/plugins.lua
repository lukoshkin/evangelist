local packer = require'lib.packer-init'
--- Sections: CORE, APPEARANCE, MISCELLANEA, IDE-LIKE

packer.startup(function (use)
  use 'wbthomason/packer.nvim'
  use {
    'williamboman/mason.nvim',
    config = function ()
      require'mason'.setup()
    end
  }


  --- CORE
  use {
    'simnalamburt/vim-mundo',
    keys = '<Leader>u',
    config = function()
      require'user.plugins.undo'
    end
  }

  use {
    'kyazdani42/nvim-tree.lua',
    requires = 'kyazdani42/nvim-web-devicons',
    config = function ()
      require'user.plugins.nvim-tree'
    end
  }

  use {
    'nvim-telescope/telescope.nvim',
    requires = {
      'nvim-lua/plenary.nvim',
      'kyazdani42/nvim-web-devicons',
      'AckslD/nvim-neoclip.lua',
      'rcarriga/nvim-notify',
      { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
      'nvim-telescope/telescope-live-grep-args.nvim',
      'ahmedkhalf/project.nvim',
    },
    config = function ()
      require'user.plugins.telescope'
    end
  }


  --- APPEARANCE
  use 'lukoshkin/highlight-whitespace'
  use 'lukoshkin/unititle.nvim'
  use {
    'EdenEast/nightfox.nvim',
    config = function ()
      require'user.plugins.colors'
    end
  }

  use {
    'akinsho/bufferline.nvim',
    event = 'BufRead',
    requires = 'kyazdani42/nvim-web-devicons',
    config = function ()
      require'user.plugins.bufferline'
    end
  }

  use {
    'nvim-lualine/lualine.nvim',
    requires = 'kyazdani42/nvim-web-devicons',
    config = function ()
      require'user.plugins.lualine'
    end
  }

  use {
    'lewis6991/gitsigns.nvim',
    event = 'BufRead',
    requires = 'nvim-lua/plenary.nvim',
    config = function ()
      require'user.plugins.gitsigns'
    end
  }


  --- MISCELLANEA
  use 'sickill/vim-pasta'
  -- use {
  --   'sickill/vim-pasta',
  --   config = function ()
  --     vim.g.pasta_disabled_filetypes = {
  --       'python',
  --       'yaml',
  --       'coffee',
  --       'markdown',
  --       'slim',
  --       'nerdtree',
  --       'netrw',
  --       'startify',
  --       'ctrlp'
  --       }
  --   end
  -- }
  use 'tpope/vim-sleuth'
  use 'tpope/vim-eunuch'
  use 'jessarcher/vim-heritage'

  use {
    'rcarriga/nvim-notify',
    config = function ()
      require'user.plugins.notify'
    end
  }

  use {
    'unblevable/quick-scope',
    config = function ()
      require'user.plugins.quick-scope'
    end
  }

  use {
    'mhinz/vim-sayonara',
    setup = function ()
      vim.keymap.set('n', '<Leader>q', ':Sayonara!<CR>')
    end
  }

  use {
    'lervag/vimtex',
    ft = 'tex',
    setup = function ()
      vim.g.vimtex_compiler_progname = 'nvr'
      vim.g.tex_flavor = 'xelatex'
    end
  }

  use {
    { 'tpope/vim-commentary',     keys  = 'gc' },
    { 'farmergreg/vim-lastplace', event = 'BufRead' },
    { 'tpope/vim-repeat',         event = 'BufRead' },
    { 'dstein64/vim-startuptime', cmd   = 'StartupTime' },
    { 'tpope/vim-surround',       event = 'BufRead' },
    --- keys = {'ys', 'cs', 'ds' }}, --> malfunctioning with 'ds'
    {
      'junegunn/vim-easy-align',
      keys = 'ga',
      config = function ()
        require'user.plugins.vim-easy-align'
      end
    },
  }

  use {
    'iamcco/markdown-preview.nvim',
    ft = 'markdown',
    run = function() vim.fn['mkdp#util#install']() end,
    config = function ()
      require'user.plugins.md-preview'
    end
  }

  use {
    'AckslD/nvim-neoclip.lua',
    requires = {
      --- is only required if persistent history is enabled.
      -- {'tami5/sqlite.lua', module = 'sqlite'},
      {'nvim-telescope/telescope.nvim'},
    },
    config = function()
      require'user.plugins.neoclip'
    end
  }


  --- IDE-LIKE
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate | :TSInstall! query',
    requires = {
      'nvim-treesitter/playground',
      'nvim-treesitter/nvim-treesitter-textobjects',
      'JoosepAlviste/nvim-ts-context-commentstring',
    },
    config = function ()
      require'user.plugins.treesitter'
    end
  }

  use {
    'neovim/nvim-lspconfig',
    requires = {
      'folke/lsp-colors.nvim',
      'weilbith/nvim-code-action-menu',
      'jose-elias-alvarez/null-ls.nvim',
      'SmiteshP/nvim-navic',
    },
    config = function ()
      require'user.plugins.lspconfig'
    end
  }

  use {
    'ray-x/lsp_signature.nvim',
    --- Looks better than cmp-nvim-lsp-signature-help.
    config = function ()
      require'lsp_signature'.setup()
    end
  }

  use {
    'hrsh7th/nvim-cmp',
    requires = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'dmitmel/cmp-digraphs',
      'saadparwaiz1/cmp_luasnip',
      'rafamadriz/friendly-snippets',
      'L3MON4D3/LuaSnip',
      'jessarcher/cmp-path',
      {
        'tzachar/cmp-tabnine',
        run='./install.sh'
      },
      'hrsh7th/cmp-nvim-lua',
      'onsails/lspkind-nvim',
    },
    config = function ()
      require'user.plugins.cmp'
    end
  }

  -- use {
  --   'puremourning/vimspector',
  --   config = function ()
  --     require'user.plugins.vimspector'
  --   end
  -- }

  use {
    'mfussenegger/nvim-dap',
    requires = {
      'rcarriga/nvim-dap-ui',
      'mfussenegger/nvim-dap-python',
      'nvim-telescope/telescope-dap.nvim',
    },
    config = function ()
      require'user.plugins.dap'
    end
  }

  use {
    'kkoomen/vim-doge',
    run = ':call doge#install()',
    ft = { 'python', 'rust', 'bash', 'lua', 'cpp', 'c' },
    setup = function ()
      vim.g.doge_doc_standard_python = 'numpy'
      vim.g.doge_enable_mappings = false
      vim.keymap.set('n', '<LocalLeader>dg', ':DogeGenerate<CR>')
    end
  }

  use {
    'ahmedkhalf/project.nvim',
    config = function()
      require'project_nvim'.setup {
        --- use pattern. If it doesn't find anything, use lsp.
        --- https://github.com/ahmedkhalf/project.nvim/issues/67
        -- detection_methods = { 'pattern', 'lsp' },

        ignore_lsp = {'null-ls'},

        -- manual_mode = true,
        -- silent_chdir = false, -- for debug
      }
    end
  }

  use {
    'rxi/json.lua',
    run = 'mkdir -p lua/json && mv json.lua lua/json/init.lua',
  }

  use {
    'lukoshkin/slime-wrapper.nvim',
    requires = {
      'jpalardy/vim-slime',
      'hanschen/vim-ipython-cell',
      'lukoshkin/bterm.nvim',
      'lukoshkin/auenv.nvim',
    },
    config = function ()
      if vim.env.CONDA_PREFIX ~= nil then
        require'auenv'.setup()
      end

      require'bottom-term'.setup()
      require'slime-wrapper'.setup()
    end
  }
end)
