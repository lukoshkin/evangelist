local M = {}

local nls = require'null-ls'
local nls_utils = require'null-ls.utils'
local nls_sources = require'null-ls.sources'
local b_ins = nls.builtins

local notify = require'notify'
local fn = require'lib.function'

local with_diagnostics_code = function (builtin)
  return builtin.with {
    diagnostics_format = "#{m} [#{c}]",
  }
end

local with_root_file = function (builtin, file)
  return builtin.with {
    condition = function (utils)
      return utils.root_has_file(file)
    end,
  }
end

local sources = {
  -- formatting
  b_ins.formatting.prettierd,
  b_ins.formatting.shfmt,
  b_ins.formatting.fixjson,
  b_ins.formatting.black.with { extra_args = { "--fast" } },
  b_ins.formatting.isort,
  with_root_file(b_ins.formatting.stylua, "stylua.toml"),

  -- diagnostics
  b_ins.diagnostics.write_good,
  b_ins.diagnostics.flake8,
  b_ins.diagnostics.pylint,
  with_root_file(b_ins.diagnostics.selene, "selene.toml"),
  with_diagnostics_code(b_ins.diagnostics.shellcheck),

  -- code actions
  b_ins.code_actions.gitsigns,
  b_ins.code_actions.gitrebase,

  -- hover
  b_ins.hover.dictionary,
}

--- Custom actions
local format_text = {
  method = nls.methods.CODE_ACTION,
  filetypes = {},
  generator = {
    fn = function (_)
      return {{
        title = 'Format code',
        action = vim.lsp.buf.formatting
      }}
    end
  }
}

local organize_imports = {
  method = nls.methods.CODE_ACTION,
  filetypes = { 'python' },
  generator = {
    fn = function (_)
      return {{
        title = 'Organize imports (pyright)',
        action = function ()
          vim.cmd ':PyrightOrganizeImports'
        end
      }}
    end
  }
}


local function in_compare_mode (normal_windows)
  if vim.t.ca_cmp_bufs == nil then
    return false
  end

  if #normal_windows < 2 then
    return false
  end

  for _, v in pairs(vim.t.ca_cmp_bufs) do
    if not vim.tbl_contains(normal_windows, v) then
      return false
    end
  end

  return true
end


local function cmp_two_bufs ()
  vim.t.ca_cmp_bufs = fn.only_normal_windows()

  --- winnr() checks the number of wins IN A TAB.
  if vim.fn.winnr() == 2 then
    --- Ensure the 2nd win is on the right.
    vim.cmd 'wincmd L'
  end

  local back_to_wid = vim.fn.win_getid()
  --- ':windo' doesn't suit because of floating wins.
  for _, wid in pairs(vim.t.ca_cmp_bufs) do
    vim.fn.win_gotoid(wid)
    vim.cmd ':diffthis'
  end

  vim.fn.win_gotoid(back_to_wid)
  --- Remove notifications wins.
  if notify ~= nil then
    --- Don't try to remove them before you have drawn them.
    vim.defer_fn(function () notify.dismiss() end, 100)
  end
  --- After switching between wins, notifications about changing the root
  --- directory might appear (if the project.nvim option 'silent_chdir' is
  --- set to false). Note: removing them with the command above is
  --- a bit overkill.
end


local function stop_cmp_bufs ()
  local back_to_wid = vim.fn.win_getid()

  vim.cmd 'windo :diffoff'
  vim.t.ca_cmp_bufs = nil

  vim.fn.win_gotoid(back_to_wid)

  if notify ~= nil then
    vim.defer_fn(function () notify.dismiss() end, 100)
  end
end


local compare_buffers = {
  method = nls.methods.CODE_ACTION,
  filetypes = {},
  generator = {
    fn = function (_)
      local normal_windows = fn.only_normal_windows()

      if #normal_windows ~= 2 then
        return
      end

      if in_compare_mode(normal_windows) then
        return
      end

      return {{
        title = 'Compare buffers',
        action = cmp_two_bufs
      }}
    end
  }
}

local stop_comparing_buffers = {
  method = nls.methods.CODE_ACTION,
  filetypes = {},
  generator = {
    fn = function (_)
      if not in_compare_mode(fn.only_normal_windows()) then
        return
      end

      return {{
        title = 'Stop comparing',
        action = stop_cmp_bufs
      }}
    end
  }
}


function M.list_registered (ft, method_string)
  local registered = {}
  for _, src in pairs(nls_sources.get_available(ft)) do
    for method in pairs(src.methods) do
      --- the next line is sth like Python `defaultdict` implementation.
      registered[method] = registered[method] or {}
      table.insert(registered[method], src.name)
    end
  end

  local method = nls.methods[string.upper(method_string)]
  return registered[method] or {}
end


--- I guess `list_supported` lists all sources null-ls supports
--- (for current buffer filetype), while `list_registered` shows
--- only installed sources from those listed in the local var `sources`.
function M.list_supported (ft, method)
  local sup = nls_sources.get_supported(ft, method)
  table.sort(sup)
  return sup
end


local function has_formatter (ft)
  local method = nls.methods.FORMATTING
  local available = nls_sources.get_available(ft, method)
  return #available > 0
end


--- Not sure it this helps in any way.
function M.setup_formatters (client, bufnr)
  local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")

  local enable = false
  if has_formatter(ft) then
    enable = client.name == "null-ls"
  else
    enable = not (client.name == "null-ls")
  end

  client.server_capabilities.documentFormatting = enable
end


function M.setup (on_attach)
  nls.register(format_text)
  nls.register(organize_imports)
  nls.register(compare_buffers)
  nls.register(stop_comparing_buffers)

  nls.setup {
    save_after_format = false,
    sources = sources,
    on_attach = on_attach,
    root_dir = nls_utils.root_pattern ".git",
  }
end


return M
