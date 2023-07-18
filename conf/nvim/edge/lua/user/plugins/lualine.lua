local nls_conf = require'user.plugins.null-ls'
local unique = require'lib.utils'.unique
local api = vim.api


local function lsp_clients ()
  local msg = 'None'
  local clients = vim.lsp.buf_get_clients()

  if next(clients) == nil then
    return msg
  end

  local client_names = {}
  local buf_ft = api.nvim_buf_get_option(0, 'filetype')

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


local function conda_env ()
  local msg = ''
  local buf_ft = api.nvim_buf_get_option(0, 'filetype')

  if buf_ft == 'python' then
    msg = '(' .. vim.env.CONDA_DEFAULT_ENV .. ')'
  end

  return msg
end


local function cursor_column ()
  local x = vim.fn.col('.')
  local msg = ''

  if x > 1 then
    msg = string.format('♟ %d', x)
  end

  return msg
end


require('lualine').setup {
  options = {
    globalstatus = true,
    theme = 'nord',
    -- component_separators = { left = '', right = ''},
    -- section_separators = { left = '', right = ''},

    --- Default separators occupies too much space.
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
  },
  sections = {
    --- Never contracted, highlighted in theme colors.
    lualine_a = {
      { function () return '★☭  ' end,
        color = function ()
          if api.nvim_get_mode().mode == 'c' then
            return { fg = 'yellow', bg = 'PaleVioletRed3' }
          end
          return { fg = 'black' }
        end }
    },
    --- Never contracted.
    lualine_b = {
      'branch',
      { conda_env,
        icon ='',
        color = { fg = 'DarkOliveGreen3' }},
      'diff',
      'diagnostics'
    },
    --- The next two will be contracted if there is not
    --- enough space for displaying a,b,y,z sections.
    lualine_c = {},
    lualine_x = {
      --- Get only the cursor column.
      { cursor_column,
        color = { gui = 'bold', fg = 'plum' } },
      { lsp_clients,
        icon = ' LSP:',
        color = { fg = '#87afff' },
        --- Other colors I like:
        -- color = { fg = 'MediumPurple1' },
        -- color = { fg = 'DeepSkyBlue2' },
        -- color = { fg = 'plum' },
      },
      --- The following two are bulky and uninformative.
      -- 'encoding',
      -- 'fileformat',
    },
    --- This one repeats bufferline and winbar in some sense.
    lualine_y = {
    --   'filetype',
    },
    lualine_z = {
      'progress',
    },
  },
  --- What to display for windows not containing the cursor.
  inactive_sections = {
    lualine_c = {
      { 'filename',
        color = {
          gui = 'bold',
          -- fg = 'LightSteelBlue',
          fg = 'LightSlateGray',
        },
      },
    },
    --- Don't display section 'x'.
    --- Other sections are not displayed by default.
    lualine_x = {},
  },
}
