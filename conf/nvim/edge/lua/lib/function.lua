local fn = vim.fn
local api = vim.api
local unpack = unpack or table.unpack
local M = {}

function M.toggle_mouse()
  --- https://unix.stackexchange.com/questions/156707
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


function M.trim ()
  local pos = api.nvim_win_get_cursor(0)
  if fn.search('\\s\\+$') <= 0 then
    vim.notify(' Nothing to trim!')
    return
  end

  local l1, r1 = unpack(api.nvim_buf_get_mark(0, '<'))
  local l2, r2 = unpack(api.nvim_buf_get_mark(0, '>'))

  local cmd = 's/\\s\\+$//e'
  local range = '%'

  if l2 - l1 ~= 0 or r2 - r1 ~= 0 then
    range = l1 .. ',' .. l2
  end

  cmd = range .. cmd .. '| nohlsearch'
  vim.cmd(cmd)

  api.nvim_win_set_cursor(0, pos)
  vim.notify(' Trimmed!')
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

--- Paste into the current buffer return value of a command or its output to
--- stdout (if no return value). Useful when the inspection of the cmd output
--- is limited, and interaction in the buffer is more convenient.
function M.paste_into_buffer (cmd)
  local lang = cmd.fargs[2]
  local call = load('return ' .. cmd.fargs[1])
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


return M
