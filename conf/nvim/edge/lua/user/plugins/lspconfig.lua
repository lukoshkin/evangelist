local api = vim.api
local lspconfig = require "lspconfig"
local buf_keymap = require("lib.utils").buf_keymap

local servers = {
  "clangd",
  "bashls",
  "dockerls",
  "jsonls",
  "marksman",
}

for _, lsp in pairs(servers) do
  lspconfig[lsp].setup {}
end

--- Add clippy linting (includes performance hints).
lspconfig.rust_analyzer.setup {
  settings = {
    ["rust-analyzer"] = {
      checkOnSave = {
        allFeatures = true,
        overrideCommand = {
          "cargo",
          "clippy",
          "--workspace",
          "--message-format=json",
          "--all-targets",
          "--all-features",
        },
      },
    },
  },
}
lspconfig.pyright.setup {
  settings = {
    python = {
      analysis = { diagnosticMode = "off", typeCheckingMode = "off" },
    },
  },
}

local runtime_path = vim.split(package.path, ";")
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")
lspconfig.lua_ls.setup {
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      runtime = { version = "LuaJIT", path = runtime_path },
    },
    workspace = { library = api.nvim_get_runtime_file("", true) },
    telemetry = { enable = false },
  },
}

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_keymap(ev.buf, "n", "gD", vim.lsp.buf.declaration)
    buf_keymap(ev.buf, "n", "gd", vim.lsp.buf.definition)
    buf_keymap(ev.buf, "n", "K", vim.lsp.buf.hover)
    buf_keymap(ev.buf, "n", "gs", vim.lsp.buf.signature_help)
    buf_keymap(ev.buf, "n", "<Leader>td", vim.lsp.buf.type_definition)
    buf_keymap(ev.buf, "n", "<Leader>rn", vim.lsp.buf.rename)
    buf_keymap(ev.buf, "n", "gr", ":Telescope lsp_references<CR>")
    --- gi and gI are reserved by original Vim command (see :h gi, e.g.).
    buf_keymap(ev.buf, "n", "<Leader>i", vim.lsp.buf.implementation)

    --- A standard lsp approach would be
    --- vim.lsp.buf.xxx_action()
    ---               or
    --- ':Telescope lsp_xxx_actions<CR>'
    --- where 'xxx' is 'code' or 'range_code'.

    --- 'ge' like (E)xplain (E)rror.
    buf_keymap(ev.buf, "n", "ge", vim.diagnostic.open_float)
    --- ][d for looping over all diagnostic messages.
    buf_keymap(ev.buf, "n", "[d", function()
      vim.diagnostic.goto_prev {
        severity = { min = vim.diagnostic.severity.INFO },
      }
    end)
    buf_keymap(ev.buf, "n", "]d", function()
      vim.diagnostic.goto_next {
        severity = { min = vim.diagnostic.severity.INFO },
      }
    end)
    --- ][e ─ over just error messages.
    buf_keymap(ev.buf, "n", "[e", function()
      vim.diagnostic.goto_prev { severity = vim.diagnostic.severity.ERROR }
    end)
    buf_keymap(ev.buf, "n", "]e", function()
      vim.diagnostic.goto_next { severity = vim.diagnostic.severity.ERROR }
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
