local fn = vim.fn
local api = vim.api
local M = {}


function M.only_normal_windows ()
  local normal_windows = vim.tbl_filter(function (key)
    return api.nvim_win_get_config(key).relative == ''
  end, api.nvim_tabpage_list_wins(0))
  return normal_windows
end


function M.toggle_mouse ()
  if vim.o.mouse == 'a' then
    vim.o.mouse = ''
  else
    vim.o.mouse = 'a'
  end
end


function M.dismiss_distractive ()
  require'notify'.dismiss()
  vim.cmd ':nohlsearch | echo'
end


function M.toggle_numbers_signs ()
  if vim.opt.number:get() ~= vim.opt.relativenumber:get() then
    vim.opt.number = vim.opt.relativenumber:get()
  end

  vim.opt.number = not vim.opt.number:get()
  vim.opt.relativenumber = not vim.opt.relativenumber:get()

  if vim.opt.signcolumn:get() == 'no' then
    vim.opt.signcolumn = 'yes'
  else
    vim.opt.signcolumn = 'no'
  end
end


function M.toggle_diags ()
  if vim.b.diag_active ~= false then
    vim.diagnostic.hide(nil, 0)
    vim.b.diag_active = false
  else
    vim.diagnostic.show(nil, 0)
    vim.b.diag_active = true
  end
end


function M.toggle_numbers_signs_diags ()
  if vim.opt.number:get() ~= vim.opt.relativenumber:get() then
    vim.opt.number = vim.opt.relativenumber:get()
  end

  vim.opt.number = not vim.opt.number:get()
  vim.opt.relativenumber = not vim.opt.relativenumber:get()

  if vim.opt.signcolumn:get() == 'no' then
    vim.opt.signcolumn = 'yes'
    if vim.b.diag_active == false then
      M.toggle_diags()
    end
  else
    vim.opt.signcolumn = 'no'
    if vim.b.diag_active ~= false then
      M.toggle_diags()
    end
  end
end


function M.trim (opts)
  --- Second arg is 'flags' string:
  --- 'n' - do NOT move cursor;
  --- 'b' - search in the backward direction.
  --- Third arg is 'endline'. If the end line is given, the search
  --- starts from the line where the cursor is currently located.
  if fn.search('\\s\\+$', 'n', opts.line2) <= 0
      and fn.search('\\s\\+$', 'bn', opts.line1) <= 0 then
    vim.notify(' Nothing to trim!\n (Search range: '
      .. opts.line1 .. '-' .. opts.line2 .. ' lines)')
    return
  end

  local pos = api.nvim_win_get_cursor(0)
  local cmd = opts.line1 .. ',' .. opts.line2
    .. 's/\\s\\+$//e' .. '| nohlsearch'
  vim.cmd(cmd)

  api.nvim_win_set_cursor(0, pos)
  vim.notify(' Trimmed!')
end


function M.narrow_win_nowrap ()
  for _, wid in pairs(M.only_normal_windows()) do
    local tw = api.nvim_win_get_width(wid)
    if tw < 110 then
      api.nvim_win_set_option(wid, 'wrap', false)
    else
      api.nvim_win_set_option(wid, 'wrap', true)
    end
  end
end


function M.resize (arg, opts)
  local cmd = 'resize ' .. arg
  opts = opts or {}

  if opts.vertical then
    cmd = 'vertical ' .. cmd
  end

  vim.cmd(cmd)
  M.narrow_win_nowrap()
end


vim.cmd[[
  fun! SplitBySep (...)
    "" '...' is like '*args' in Python.

    "" Note: the content of register l will be lost after the function call.
    "" Key 'l' is chosen as "the least convenient" for register use.

    "" I believe there is no need to check the num of args.
    " if a:0 > 1
    "   echoerr 'More than one argument passed'
    "   return
    " endif

    let l:sep = get(a:, 1, ' ')

    mark l
    execute 'normal 0"ly/'.l:sep.'<CR>'
    silent! execute 's;\('.l:sep.'\)\(\S\)\@=;\1\r;g'
    mark L

    " let l:len = strlen(getreg('l'))
    " let l:indent = repeat(' ', l:len)

    " 'l+1,'Ls;^;\=l:indent;

    normal 'lj
    normal ='L
    silent 'l,'LTrim

    delmarks lL
    let @l=''
  endfun
]]


function M.multi_source_completion (pat, sources)
  local all = {}
  for _, src in pairs(sources) do
    local particular = vim.fn.getcompletion(pat, src)
    all = vim.tbl_extend('keep', all, particular)
  end

  return all
end


--- Paste into the current buffer return value of a command or its output to
--- stdout (if no return value). Useful when the inspection of the cmd output
--- is limited, and interaction in the buffer is more convenient.
function M.paste_into_buffer (cmd)
  local call = load('return ' .. cmd.fargs[1])
  local lang = cmd.fargs[2]
  local return_value

  vim.cmd 'redir => _msg'
  if lang == nil or lang == 'lua' then
    return_value = call()
  else
    vim.cmd('silent ' .. cmd.fargs[1])
  end

  vim.cmd 'redir END'
  if return_value == nil then
    vim.cmd 'silent put=trim(_msg)'
    return
  end

  local lines = {}
  for line in return_value:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end

  vim.paste(lines, -1)
end


--- Print Lua or Vim function's return value in the cmdline window.
function M.print_inspect (cmd)
  xpcall(function()
    vim.cmd(':lua print(vim.inspect(' .. cmd.args .. '))')
  end, function()
    vim.cmd('echo(' .. cmd.args .. ')')
  end)

  --- The version below can print almost anything, but we actually don't need
  --- to hit the case with `vim.cmd(cmd.args)`, since the latter is equivalent
  --- to just typing `:cmd` in the cmdline.
  -- if not pcall(
  --   function()
  --     vim.cmd(':lua print(vim.inspect(' .. cmd.args .. '))')
  --   end) then
  --   if not pcall(function ()
  --     vim.cmd(cmd.args)
  --   end) then
  --     vim.cmd('echo(' .. cmd.args .. ')')
  --   end
  -- end
end


--- Custom completion function for Insert (M.paste_into_buffer)
--- and Print (M.print_inspect) commands. (Currently, in beta state.)
function M.complete_lua_or_vim (arg_lead)
  local sources = { 'lua', 'expression', 'option' }
  local pat = arg_lead:match'^.+%.(.+)$' or arg_lead
  local prefix = arg_lead:match'^(.+%.).+$'

  if arg_lead:match'%.' then
    if arg_lead:match'%.[gbw]?o%.'
      or arg_lead:match'%.opt%.' then
      sources = { 'option' }
    end
  end

  local all = M.multi_source_completion(pat, sources)
  if prefix ~= nil and prefix ~= '' then
    all = vim.tbl_map(function (val)
      return prefix .. val
    end, all)
  end

  return all
end


return M
