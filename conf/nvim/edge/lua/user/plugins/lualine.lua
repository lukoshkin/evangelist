local unique = require("lib.utils").unique
local api = vim.api

local linters = {}
api.nvim_create_autocmd("BufDelete", {
  group = api.nvim_create_augroup("Lualine", { clear = true }),
  callback = function()
    local bufname = api.nvim_buf_get_name(0)
    if linters[bufname] then
      linters[bufname] = nil
    end
  end,
})

local function lsp_clients()
  local bufname = api.nvim_buf_get_name(0)
  local ft = api.nvim_get_option_value("filetype", { buf = 0 })
  if bufname ~= "" then
    linters[bufname] = linters[bufname] or {}
  end

  local client_names = vim.tbl_map(function(client)
    return client.name
  end, vim.lsp.get_clients { bufnr = 0 })

  for _, linter in ipairs(require("lint").get_running()) do
    if vim.tbl_contains(require("lint").linters_by_ft[ft], linter) then
      if bufname ~= "" and not vim.tbl_contains(linters[bufname], linter) then
        table.insert(linters[bufname], linter)
      end
    end
  end
  vim.list_extend(client_names, linters[bufname])

  local formatters = require("conform").list_formatters_for_buffer(0)
  vim.list_extend(client_names, formatters)

  if next(client_names) then
    return "[" .. table.concat(unique(client_names), ", ") .. "]"
  end

  return "None"
end

local function conda_env()
  local msg = ""
  local buf_ft = api.nvim_get_option_value("filetype", { buf = 0 })

  if buf_ft == "python" then
    msg = "(" .. vim.env.CONDA_DEFAULT_ENV .. ")"
  end

  return msg
end

local function cursor_column()
  local x = vim.fn.col "."
  local msg = ""

  if x > 1 then
    msg = string.format("♟ %d", x)
  end

  return msg
end

return {
  "nvim-lualine/lualine.nvim",
  dependencies = "nvim-tree/nvim-web-devicons",
  linters = linters,
  opts = {
    options = {
      globalstatus = true,
      theme = "nord",
      -- component_separators = { left = '', right = ''},
      -- section_separators = { left = '', right = ''},

      --- Default separators occupies too much space.
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
    },
    sections = {
      --- Never contracted, highlighted in theme colors.
      lualine_a = {
        {
          function()
            return "★☭  "
          end,
          color = function()
            if api.nvim_get_mode().mode == "c" then
              return { fg = "yellow", bg = "PaleVioletRed3" }
            end
            return { fg = "black" }
          end,
        },
      },
      --- Never contracted.
      lualine_b = {
        "branch",
        { conda_env, icon = "", color = { fg = "DarkOliveGreen3" } },
        "diff",
        "diagnostics",
      },
      --- The next two will be contracted if there is not
      --- enough space for displaying a,b,y,z sections.
      lualine_c = {},
      lualine_x = {
        --- Get only the cursor column.
        { cursor_column, color = { gui = "bold", fg = "plum" } },
        {
          lsp_clients,
          icon = " Tools:",
          color = { fg = "#87afff" },
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
        "progress",
      },
    },
    --- What to display for windows not containing the cursor.
    inactive_sections = {
      lualine_c = {
        {
          "filename",
          color = {
            gui = "bold",
            -- fg = 'LightSteelBlue',
            fg = "LightSlateGray",
          },
        },
      },
      --- Don't display section 'x'.
      --- Other sections are not displayed by default.
      lualine_x = {},
    },
  },
}
