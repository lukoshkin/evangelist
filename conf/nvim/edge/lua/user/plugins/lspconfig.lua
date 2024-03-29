local api = vim.api
local buf_option = vim.api.nvim_buf_set_option
local buf_keymap = require'lib.utils'.buf_keymap
local nls_conf = require'user.plugins.null-ls'

-- local ns = api.nvim_create_namespace('copy-from-help-diagnostic-handlers')
-- local orig_virt_text_handler = vim.diagnostic.handlers.virtual_text

-- vim.diagnostic.handlers.virtual_text = {
--   show = function (_, bufnr, diagnostics, opts)
--     local line_sign_cnt = {}
--     local hash = {}
--     for _, d in pairs(diagnostics) do
--       hash[d.lnum] = hash[d.lnum] or {}
--       if not hash[d.lnum][d.message] then
--         line_sign_cnt[d.lnum] = line_sign_cnt[d.lnum] or 0
--         line_sign_cnt[d.lnum] = line_sign_cnt[d.lnum] + 1
--         hash[d.lnum][d.message] = true
--       end
--     end

--     for i, d in ipairs(diagnostics) do
--       local twcol = 80 - #vim.fn.getline(d.lnum+1)
--       if twcol >= 0 then twcol = 81 else twcol = 82 - twcol end

--       api.nvim_buf_set_extmark(
--         bufnr, ns, d.lnum, d.col,
--         { id=i,
--           virt_text = {{ string.rep('◆', line_sign_cnt[d.lnum]) }},
--           virt_text_win_col = twcol,
--         })
--     end
--   end,

--   hide = function (_, bufnr)
--     orig_virt_text_handler.hide(ns, bufnr)
--   end
-- }

--- Override the handler for diagnostic signs to show only a sign
--- for the highest severity diagnostic on a given line. The code below
--- follows the help message for 'diagnostic-handlers-example'.

--- Create a custom namespace. This will aggregate signs from all other
--- namespaces and only show the one with the highest severity on a given line
local ns = api.nvim_create_namespace('copy-from-help-diagnostic-handlers')


--- Get a reference to the original signs handler
local orig_signs_handler = vim.diagnostic.handlers.signs

--- Override the built-in signs handler
vim.diagnostic.handlers.signs = {
  show = function(_, bufnr, _, opts)
    --- Get all diagnostics from the whole buffer rather than just the
    --- diagnostics passed to the handler
    local diagnostics = vim.diagnostic.get(bufnr)

    --- Find the "worst" diagnostic per line
    local max_severity_per_line = {}
    for _, d in pairs(diagnostics) do
      local m = max_severity_per_line[d.lnum]
      if not m or d.severity < m.severity then
        max_severity_per_line[d.lnum] = d
      end
    end

    --- Pass the filtered diagnostics (with our custom namespace) to
    --- the original handler
    local filtered_diagnostics = vim.tbl_values(max_severity_per_line)
    orig_signs_handler.show(ns, bufnr, filtered_diagnostics, opts)
  end,
  hide = function(_, bufnr)
    orig_signs_handler.hide(ns, bufnr)
  end,
}

vim.diagnostic.config {
  severity_sort = true,

  signs = true,
  virtual_text = {
    source = false,
    format = function (_)
      return ''
    end
  },

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
  },
}


local function set_lsp_mappings (client, bufnr)
  buf_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  buf_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
  buf_keymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
  buf_keymap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
  buf_keymap(bufnr, 'n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
  buf_keymap(bufnr, 'n', '<Leader>td', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
  buf_keymap(bufnr, 'n', '<Leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>')
  buf_keymap(bufnr, 'n', 'gr', ':Telescope lsp_references<CR>')
  --- gi and gI are reserved by original Vim command (see :h gi, e.g.).
  buf_keymap(bufnr, 'n', '<Leader>i', '<cmd>lua vim.lsp.buf.implementation()<CR>')

  --- Provided by 'weilbith/nvim-code-action-menu':
  buf_keymap(bufnr, 'n', '<Leader>ca', ':CodeActionMenu<CR>')
  buf_keymap(bufnr, 'v', '<Leader>ca', ':CodeActionMenu<CR>')
  --- A standard lsp approach would be
  --- '<cmd>lua vim.lsp.buf.xxx_action()<CR>'
  ---               or
  --- ':Telescope lsp_xxx_actions<CR>'
  --- where 'xxx' is 'code' or 'range_code'.

  --- 'ge' like (E)xplain (E)rror.
  buf_keymap(bufnr, 'n', 'ge', '<cmd>lua vim.diagnostic.open_float()<CR>')
  --- ][d for looping over all diagnostic messages.
  buf_keymap(bufnr, 'n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>')
  buf_keymap(bufnr, 'n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>')
  --- ][e ─ over just error messages.
  buf_keymap(
    bufnr, 'n', '[e', '<cmd>lua vim.diagnostic.goto_prev('
    .. '{severity = vim.diagnostic.severity.ERROR})<CR>')
  buf_keymap(
    bufnr, 'n', ']e', '<cmd>lua vim.diagnostic.goto_next('
    .. '{severity = vim.diagnostic.severity.ERROR})<CR>')


  --- Open full diagnostics in location-list + find symbols(primitive data type) using telescope.
  buf_keymap(bufnr, 'n', '<Space>q', '<cmd>lua vim.diagnostic.setloclist()<CR>')
  buf_keymap(bufnr, 'n', '<Leader>fs', [[<cmd>lua require('telescope.builtin').lsp_document_symbols()<CR>]])

  api.nvim_create_user_command(
    'Format',
    vim.lsp.buf.formatting,
    {}
  )

  if client.server_capabilities.documentFormatting then
    api.nvim_buf_set_option(bufnr, 'formatexpr', 'v:lua.vim.lsp.formatexpr()')
    buf_keymap(bufnr, 'n', '<leader>gq', '<cmd>lua vim.lsp.buf.format({async = true})')
  else
    api.nvim_buf_set_option(bufnr, 'formatexpr', '')
  end
end


local on_attach = function(client, bufnr)
  set_lsp_mappings(client, bufnr)
  nls_conf.setup_formatters(client, bufnr)
end

--- nvim-cmp supports additional completion capabilities
local capabilities = require(
  'cmp_nvim_lsp').default_capabilities(
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

--- Lua setup follows this guide:
--- https://jdhao.github.io/2021/08/12/nvim_sumneko_lua_conf/
--- FIXME: multiple instances sumneko_lua.
--- https://github.com/neovim/nvim-lspconfig/issues/319
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
        --- Get the language server to recognize the `vim` global
        globals = { 'vim' },
      },
      runtime = {
        version = 'LuaJIT',
        path = runtime_path,
      },
    },
    workspace = {
      --- Make the server aware of Neovim runtime files
      library = api.nvim_get_runtime_file('', true),
    },
    --- Do not send telemetry data containing a randomized but unique identifier
    telemetry = {
      enable = false,
    },
  },
}


--- Configure null-ls here so it reuses `on_attach`.
nls_conf.setup(on_attach)


vim.fn.sign_define('DiagnosticSignError', { text = '', texthl = 'DiagnosticSignError' })
vim.fn.sign_define('DiagnosticSignWarn', { text = '', texthl = 'DiagnosticSignWarn' })
vim.fn.sign_define('DiagnosticSignInfo', { text = '', texthl = 'DiagnosticSignInfo' })
vim.fn.sign_define('DiagnosticSignHint', { text = '', texthl = 'DiagnosticSignHint' })

--- We use notify.nvim for notifications. Not sure if they two work coherently.
--- So it should remain commented out, until I figure it out.
-- --- Suppress error messages from lang servers.
-- vim.notify = function(msg, log_level, _)
--   if msg:match 'exit code' then
--     return
--   end
--   if log_level == vim.log.levels.ERROR then
--     api.nvim_err_writeln(msg)
--   else
--     api.nvim_echo({ { msg } }, true, {})
--   end
-- end
