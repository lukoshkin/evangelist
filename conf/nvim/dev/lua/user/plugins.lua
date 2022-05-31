local packer = require'lib.packer-init'

packer.startup(function (use)
  use 'wbthomason/packer.nvim'

  use 'sickill/vim-pasta'
  use 'tpope/vim-sleuth'
  use 'tpope/vim-eunuch' -- Adds useful commands like :SudoWrite and etc.

  use 'jessarcher/vim-heritage' -- Automatically create parent dirs when saving

  use {
    'mhinz/vim-sayonara',
    setup = function ()
      vim.keymap.set('n', '<Leader>q', ':Sayonara!<CR>')
    end
  }

  use {
    'jpalardy/vim-slime',
    ft = {'sh', 'bash', 'zsh', 'python', 'lua'},
    config = function ()
      require'user.plugins.vim-slime'
    end
  }

  use {
    'hanschen/vim-ipython-cell',
    ft = 'python',
    config = function ()
      require'user.plugins.vim-ipython-cell'
    end
  }

  use {
    'puremourning/vimspector',
    requires = 'szw/vim-maximizer',
    config = function ()
      require'user.plugins.vimspector'
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
    { 'tpope/vim-commentary',     keys  = 'gc'},
    { 'tpope/vim-surround',       event = 'BufRead'}, -- keys = {'ys', 'cs', 'ds' }}, --> malfunctioning with 'ds'
    { 'farmergreg/vim-lastplace', event = 'BufRead' },
    { 'tpope/vim-repeat',         event = 'BufRead'},
    { 'dstein64/vim-startuptime', cmd   = 'StartupTime'},
  }

  use {
    "iamcco/markdown-preview.nvim",
    ft = 'markdown',
    run = function() vim.fn["mkdp#util#install"]() end,
    config = function ()
      require'user.plugins.md_preview'
    end
  }

  use {
    'tommcdo/vim-lion',
    keys  = {'gl', 'gL'},
    config = function ()
      require'user.plugins.lion'
    end
  }

  use {
    --- Also required by telescope.
    'ahmedkhalf/project.nvim',
    config = function()
      require("project_nvim").setup { manual_mode = true }
    end
  }

  --- LOOK
  use {
    'glepnir/dashboard-nvim',
    config = function ()
      require'user.plugins.dashboard'
    end
  }

  use {
    'shaunsingh/nord.nvim',
    config = function ()
      require'user.plugins.nord'
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
      require'lualine'.setup {
        options = { theme = 'nord' },
      }
    end
  }

  use {
    'j-hui/fidget.nvim',
    config = function () require'fidget'.setup() end
  }
  ---

  use {
    'simnalamburt/vim-mundo',
    keys = '<leader>u',
    config = function()
      require'user.plugins.undo'
    end
  }

  -- use {
  --   'AndrewRadev/splitjoin.vim',
  --   config = function ()
  --     require'user.plugins.splitjoin'
  --   end
  -- }

  use {
    'kyazdani42/nvim-tree.lua',
    requires = 'kyazdani42/nvim-web-devicons',
    config = function ()
      require'user.plugins.nvim-tree'
    end
  }

  use {
    'voldikss/vim-floaterm',
    keys = '<A-t>',
    config = function ()
      require'user.plugins.floaterm'
    end
  }

  use {
    'nvim-telescope/telescope.nvim',
    requires = {
      { 'nvim-lua/plenary.nvim' },
      { 'kyazdani42/nvim-web-devicons' },
      { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
      { 'nvim-telescope/telescope-live-grep-raw.nvim' },
    },
    config = function ()
      require'user.plugins.telescope'
    end
  }

  use {
    'nvim-treesitter/nvim-treesitter',
    -- run = ':TSUpdate',
    requires = {
      'nvim-treesitter/playground',
      'nvim-treesitter/nvim-treesitter-textobjects',
      'lewis6991/spellsitter.nvim',
      'JoosepAlviste/nvim-ts-context-commentstring',
    },
    config = function ()
      require'user.plugins.treesitter'
      require'spellsitter'.setup()
    end
  }

  -- use {
  -- 'tpope/vim-fugitive',
  -- requires = 'tpope/vim-rhubarb',
  -- cmd = 'G',
  -- }

  use {
    'lewis6991/gitsigns.nvim',
    event = 'BufRead',
    requires = 'nvim-lua/plenary.nvim',
    config = function ()
      require'gitsigns'.setup { sign_priority = 20 }
    end
  }

  use {
    'neovim/nvim-lspconfig',
    requires = {
      'b0o/schemastore.nvim',
      'folke/lsp-colors.nvim',
      'weilbith/nvim-code-action-menu',
    },
    config = function ()
      require'user.plugins.lspconfig'
    end
  }

  use {
    'rafamadriz/friendly-snippets',
    --- Check if the following setup is necessary;
    --- The results of its application might have been cached somewhere,
    --- so you might have to clear them first before checking it out.
    setup = function ()
      require'luasnip'.filetype_extend('cpp', {'clangd'})
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
      'hrsh7th/cmp-nvim-lsp-signature-help',
    },
    config = function ()
      require'user.plugins.cmp'
    end
  }

  -- use {
  --   'luukvbaal/stabilize.nvim',
  --   config = function () require'stabilize'.setup() end
  -- }
end)
