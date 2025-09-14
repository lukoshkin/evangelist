--- NOTE: requires `neovim/nvim-lspconfig` plugin for default LSP configuration.
--- Otherwise, one will have to manually specify at least the "cmd" field.
vim.lsp.config("*", {
  capabilities = {
    textDocument = {
      semanticTokens = {
        multilineTokenSupport = true,
      },
    },
  },
})
--- The "setter" syntax also works for merging with the default settings
vim.lsp.config.pylsp = {
  root_markers = {
    "pyproject.toml",
    "setup.cfg",
    "requirements.txt",
  },
  settings = {
    pylsp = {
      plugins = {
        pylint = { enabled = true },
        pyflakes = { enabled = false },
        pycodestyle = { enabled = false },
        jedi_rename = { enabled = true },
        rope_rename = { enabled = true },
        -- (Make sure `pylsp-rope` plugin is installed in Python for Rope use)
      },
    },
  },
}
--- Comment out since not working with Rust currently.
--- Add clippy linting (includes performance hints).
-- vim.lsp.config.rust_analyzer = {
--   settings = {
--     ["rust-analyzer"] = {
--       checkOnSave = {
--         allFeatures = true,
--         overrideCommand = {
--           "cargo",
--           "clippy",
--           "--workspace",
--           "--message-format=json",
--           "--all-targets",
--           "--all-features",
--         },
--       },
--     },
--   },
-- }
vim.lsp.config("lua_ls", {
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if
        path ~= vim.fn.stdpath "config"
        and (
          vim.uv.fs_stat(path .. "/.luarc.json")
          or vim.uv.fs_stat(path .. "/.luarc.jsonc")
        )
      then
        return
      end
    end

    client.config.settings.Lua =
      vim.tbl_deep_extend("force", client.config.settings.Lua, {
        runtime = {
          -- Tell the language server which version of Lua you're using
          -- (most likely LuaJIT in the case of Neovim)
          version = "LuaJIT",
          -- Tell the language server how to find Lua modules same way as Neovim
          -- (see `:h lua-module-load`)
          path = {
            "lua/?.lua",
            "lua/?/init.lua",
          },
        },
        -- Make the server aware of Neovim runtime files
        workspace = {
          checkThirdParty = false,
          library = {
            vim.env.VIMRUNTIME,
            -- Depending on the usage, you might want to add additional paths
            -- here.
            -- '${3rd}/luv/library'
            -- '${3rd}/busted/library'
          },
          -- Or pull in all of 'runtimepath'.
          -- NOTE: this is a lot slower and will cause issues when working on
          -- your own configuration.
          -- See https://github.com/neovim/nvim-lspconfig/issues/3189
          -- library = {
          --   vim.api.nvim_get_runtime_file('', true),
          -- }
        },
      })
  end,
  settings = {
    Lua = {},
  },
})
vim.lsp.config("dockerls", {
  settings = {
    docker = {
      languageserver = {
        formatter = {
          ignoreMultilineInstructions = true,
        },
      },
    },
  },
})

local function on_attach(ev)
  local client = vim.lsp.get_client_by_id(ev.data.client_id)
  if client == nil then
    return
  end

  local ok_navic, navic = pcall(require, "nvim-navic")
  if ok_navic and client.server_capabilities.documentSymbolProvider then
    navic.attach(client, ev.buf)
  end
  --- Currently, completion is configured by 'nvim-cmp'.
  -- if client.supports_method("textDocument/completion", ev.buf) then
  --   vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
  -- end
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    on_attach(ev)
    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local buf_keymap = require("lib.utils").buf_keymap
    buf_keymap(ev.buf, "n", "gD", vim.lsp.buf.declaration)
    buf_keymap(ev.buf, "n", "gd", vim.lsp.buf.definition)
    buf_keymap(ev.buf, "n", "K", vim.lsp.buf.hover)
    buf_keymap(ev.buf, "n", "grt", vim.lsp.buf.type_definition)
    buf_keymap(ev.buf, "n", "grr", ":Telescope lsp_references<CR>")

    --- 'ge' like (E)xplain (E)rror.
    buf_keymap(ev.buf, "n", "ge", vim.diagnostic.open_float)
    --- ][d for looping over all diagnostic messages.
    buf_keymap(ev.buf, "n", "[d", function()
      vim.diagnostic.jump {
        count = -1,
        severity = { min = vim.diagnostic.severity.INFO },
      }
    end)
    buf_keymap(ev.buf, "n", "]d", function()
      vim.diagnostic.jump {
        count = 1,
        severity = { min = vim.diagnostic.severity.INFO },
      }
    end)
    --- ][e ─ over just error messages.
    buf_keymap(ev.buf, "n", "[e", function()
      vim.diagnostic.jump {
        count = -1,
        severity = vim.diagnostic.severity.ERROR,
      }
    end)
    buf_keymap(ev.buf, "n", "]e", function()
      vim.diagnostic.jump {
        count = 1,
        severity = vim.diagnostic.severity.ERROR,
      }
    end)

    --- Open full diagnostics in location-list + find symbols(primitive data type) using telescope.
    buf_keymap(ev.buf, "n", "<Space>q", vim.diagnostic.setloclist)
    buf_keymap(
      ev.buf,
      "n",
      "<Leader>fs",
      require("telescope.builtin").lsp_document_symbols
    )

    --- NOTE: to format relying only on 'textwidth' use 'gw'.
  end,
})
vim.lsp.enable {
  "bashls",
  "clangd",
  "dockerls",
  "eslint",
  "jsonls",
  "lua_ls",
  "marksman",
  "pylsp",
  "ruff",
  "rust_analyzer",
  "taplo",
  "tflint",
  "tsserver",
  "yamlls",
}
