local nls_conf = require'user.plugins.null-ls'
local unique = require'lib.utils'.unique


local function lsp_clients ()
  local msg = "No Active LSP"
  local clients = vim.lsp.buf_get_clients()

  if next(clients) == nil then
    return msg
  end

  local client_names = {}
  local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")

  for _, client in pairs(clients) do
    if client.name ~= 'null-ls' then
        table.insert(client_names, client.name)
    end
  end

  local linters = nls_conf.list_registered(buf_ft, 'diagnostics')
  vim.list_extend(client_names, linters)

  local formatters = nls_conf.list_registered(buf_ft, 'formatting')
  vim.list_extend(client_names, formatters)

  -- local code_actions = nls_conf.list_registered(buf_ft, 'code_action')
  -- vim.list_extend(client_names, code_actions)

  local hovers = nls_conf.list_registered(buf_ft, 'hover')
  vim.list_extend(client_names, hovers)

  if next(client_names) then
    return '[' .. table.concat(unique(client_names), ', ') .. ']'
  end

  return msg
end


require('lualine').setup {
  options = {
    theme = 'nord',
  },
  sections = {
    lualine_x = {
      { lsp_clients,
        icon = " LSP:",
        color = { fg = '#87afff' },
        --- Other colors I like:
        -- color = { fg = 'MediumPurple1' },
        -- color = { fg = 'DeepSkyBlue2' },
        -- color = { fg = 'plum' },
      },
      'encoding',
      'fileformat',
      'filetype'},
  },
}
