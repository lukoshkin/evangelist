return {
  {
    "williamboman/mason.nvim",
    event = "VeryLazy",
    config = true,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    event = "VeryLazy",
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
    event = "VeryLazy",
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
    event = "VeryLazy",
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
  { "neovim/nvim-lspconfig" },
  {
    "ray-x/lsp_signature.nvim",
    event = "VeryLazy",
    config = true,
  },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = "luvit-meta/library", words = { "vim%.uv" } },
      },
    },
  },
  { "Bilal2453/luvit-meta", lazy = true }, -- optional `vim.uv` typings
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
}
