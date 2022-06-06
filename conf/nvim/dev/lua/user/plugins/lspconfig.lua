local buf_option = vim.api.nvim_buf_set_option
local buf_keymap = require 'lib.utils'.buf_keymap

vim.diagnostic.config {
  --- ghost text on the right which can only be selected.
  virtual_text = false,
  severity_sort = true,
  float = {
    source = true,
    focus = false,
    format = function(diagnostic)
      if ((diagnostic.user_data ~= nil)
          and (diagnostic.user_data.lsp.code ~= nil)) then
        return string.format(
          "%s: %s", diagnostic.user_data.lsp.code, diagnostic.message)
      end

      return diagnostic.message
    end,
  }
}

local on_attach = function(_, bufnr)
  buf_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  buf_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
  buf_keymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
  buf_keymap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
  buf_keymap(bufnr, 'n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
  buf_keymap(bufnr, 'n', '<leader>td', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
  buf_keymap(bufnr, 'n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>')
  buf_keymap(bufnr, 'n', 'gr', ':Telescope lsp_references<CR>')
  --- gi is reserved by original Vim command (see :h gi).
  buf_keymap(bufnr, 'n', 'gI', '<cmd>lua vim.lsp.buf.implementation()<CR>')

  --- Provided by 'weilbith/nvim-code-action-menu':
  buf_keymap(bufnr, 'n', '<leader>ca', ':CodeActionMenu<CR>')
  buf_keymap(bufnr, 'v', '<leader>ca', ':CodeActionMenu<CR>')
  --- A standard lsp approach would be
  --- '<cmd>lua vim.lsp.buf.xxx_action()<CR>'
  ---               or
  --- ':Telescope lsp_xxx_actions<CR>'
  --- where 'xxx' is 'code' or 'range_code'.

  buf_keymap(bufnr, 'n', 'ge', '<cmd>lua vim.diagnostic.open_float()<CR>')
  buf_keymap(bufnr, 'n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>')
  buf_keymap(bufnr, 'n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>')

  --- Open full diagnostics in location-list + find symbols(primitive data type) using telescope.
  buf_keymap(bufnr, 'n', '<Space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>')
  buf_keymap(bufnr, 'n', '<leader>fs', [[<cmd>lua require('telescope.builtin').lsp_document_symbols()<CR>]])

  vim.api.nvim_create_user_command(
    'Format',
    vim.lsp.buf.formatting,
    {}
  )
end

-- nvim-cmp supports additional completion capabilities
local capabilities = require(
  'cmp_nvim_lsp').update_capabilities(
  vim.lsp.protocol.make_client_capabilities())

local servers = {
  'pyright',
  'clangd',
  'rust_analyzer',
  'bashls',
  'dockerls',
  'jsonls',
}

for _, lsp in pairs(servers) do
  require('lspconfig')[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

-- Lua setup follows this guide:
-- https://jdhao.github.io/2021/08/12/nvim_sumneko_lua_conf/
local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, 'lua/?.lua')
table.insert(runtime_path, 'lua/?/init.lua')

local lua_ls_bin = os.getenv 'XDG_DATA_HOME' .. '/lua-ls/bin/'
require 'lspconfig'.sumneko_lua.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  flags = {
    debounce_text_changes = 150,
  },
  cmd = { lua_ls_bin .. 'lua-language-server', '-E', lua_ls_bin .. 'main.lua' },
  settings = {
    Lua = {
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = { 'vim' },
      },
      runtime = {
        version = 'LuaJIT',
        path = runtime_path,
      },
    },
    workspace = {
      -- Make the server aware of Neovim runtime files
      library = vim.api.nvim_get_runtime_file('', true),
    },
    -- Do not send telemetry data containing a randomized but unique identifier
    telemetry = {
      enable = false,
    },
  },
}

vim.fn.sign_define('DiagnosticSignError', { text = '', texthl = 'DiagnosticSignError' })
vim.fn.sign_define('DiagnosticSignWarn', { text = '', texthl = 'DiagnosticSignWarn' })
vim.fn.sign_define('DiagnosticSignInfo', { text = '', texthl = 'DiagnosticSignInfo' })
vim.fn.sign_define('DiagnosticSignHint', { text = '', texthl = 'DiagnosticSignHint' })

-- Suppress error messages from lang servers.
vim.notify = function(msg, log_level, _)
  if msg:match 'exit code' then
    return
  end
  if log_level == vim.log.levels.ERROR then
    vim.api.nvim_err_writeln(msg)
  else
    vim.api.nvim_echo({ { msg } }, true, {})
  end
end
