local M = {}

local nls = require'null-ls'
local nls_utils = require'null-ls.utils'
local nls_sources = require'null-ls.sources'
local bins = nls.builtins

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
  bins.completion.spell,

  bins.formatting.prettierd,
  bins.formatting.shfmt,
  bins.formatting.rustfmt,
  bins.formatting.fixjson,
  bins.formatting.black.with {
    extra_args = {
      "--fast",
      "--line-length=79",
      "--preview",
    }
  },
  bins.formatting.isort,
  with_root_file(bins.formatting.stylua, "stylua.toml"),

  bins.diagnostics.write_good,
  bins.diagnostics.cspell,  -- grammar
  bins.formatting.codespell,  -- grammar
  bins.diagnostics.flake8.with {
    extra_args = {
      --- Ignore flake8's complaints about:
      --- * `##` and `#<not_whitespace_char>`
      --- * line break before a binary operator
      '--ignore=E265,E266,W503',
      '--max-line-length=80',
    }
  },
  bins.diagnostics.pylint,
  with_root_file(bins.diagnostics.selene, "selene.toml"),  -- Lua
  with_diagnostics_code(bins.diagnostics.shellcheck),

  bins.code_actions.gitsigns,
  bins.code_actions.gitrebase,
  bins.code_actions.cspell,

  bins.hover.dictionary,
}

--- Custom actions
local format_text = {
  method = nls.methods.CODE_ACTION,
  filetypes = {},
  generator = {
    fn = function (_)
      return {{
        title = 'Format code',
        action = function ()
          if vim.lsp.buf.format then
            vim.lsp.buf.format { async = true }
            return
          end
          vim.lsp.buf.formatting()
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
      --- The next line is sth like Python `defaultdict` implementation.
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
  nls.register(compare_buffers)
  nls.register(stop_comparing_buffers)

  nls.setup {
    fallback_severity = vim.diagnostic.severity.HINT,
    save_after_format = false,
    sources = sources,
    on_attach = on_attach,
    root_dir = nls_utils.root_pattern ".git",
  }
end


return M
