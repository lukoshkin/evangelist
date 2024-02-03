local api = vim.api
local lspconfig = require "lspconfig"
local buf_option = vim.api.nvim_buf_set_option
local buf_keymap = require("lib.utils").buf_keymap
local nls_conf = require "user.plugins.null-ls"


local function set_lsp_mappings(_, bufnr)
  buf_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
  buf_keymap(bufnr, "n", "gD", vim.lsp.buf.declaration)
  buf_keymap(bufnr, "n", "gd", vim.lsp.buf.definition)
  buf_keymap(bufnr, "n", "K", vim.lsp.buf.hover)
  buf_keymap(bufnr, "n", "gs", vim.lsp.buf.signature_help)
  buf_keymap(bufnr, "n", "<Leader>td", vim.lsp.buf.type_definition)
  buf_keymap(bufnr, "n", "<Leader>rn", vim.lsp.buf.rename)
  buf_keymap(bufnr, "n", "gr", ":Telescope lsp_references<CR>")
  --- gi and gI are reserved by original Vim command (see :h gi, e.g.).
  buf_keymap(bufnr, "n", "<Leader>i", vim.lsp.buf.implementation)

  --- A standard lsp approach would be
  --- vim.lsp.buf.xxx_action()
  ---               or
  --- ':Telescope lsp_xxx_actions<CR>'
  --- where 'xxx' is 'code' or 'range_code'.

  --- 'ge' like (E)xplain (E)rror.
  buf_keymap(bufnr, "n", "ge", vim.diagnostic.open_float)
  --- ][d for looping over all diagnostic messages.
  buf_keymap(bufnr, "n", "[d", vim.diagnostic.goto_prev)
  buf_keymap(bufnr, "n", "]d", vim.diagnostic.goto_next)
  --- ][e ─ over just error messages.
  buf_keymap(bufnr, "n", "[e", function()
    vim.diagnostic.goto_prev { severity = vim.diagnostic.severity.ERROR }
  end)
  buf_keymap(bufnr, "n", "]e", function()
    vim.diagnostic.goto_next { severity = vim.diagnostic.severity.ERROR }
  end)

  --- Open full diagnostics in location-list + find symbols(primitive data type) using telescope.
  buf_keymap(bufnr, "n", "<Space>q", vim.diagnostic.setloclist)
  buf_keymap(bufnr, "n", "<Leader>fs", require("telescope.builtin").lsp_document_symbols)

  --- NOTE: to format relying only on 'textwidth' use 'gw'.
end

local on_attach = function(client, bufnr)
  set_lsp_mappings(client, bufnr)
  nls_conf.setup_formatters(client, bufnr)
  if client.server_capabilities.documentSymbolProvider then
    require("nvim-navic").attach(client, bufnr)
  end
end

--- nvim-cmp supports additional completion capabilities
local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

local servers = {
  "clangd",
  "bashls",
  "dockerls",
  "jsonls",
}

for _, lsp in pairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

--- Add clippy linting (includes performance hints).
lspconfig.rust_analyzer.setup {
  on_attach = on_attach,
  capabilities = capabilities,
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
  on_attach = on_attach,
  capabilities = capabilities,
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
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      runtime = { version = "LuaJIT", path = runtime_path },
    },
    workspace = { library = api.nvim_get_runtime_file("", true) },
    telemetry = { enable = false },
  },
}

--- Configure null-ls here so it reuses `on_attach`.
nls_conf.setup(on_attach)
