local fn = require "lib.function"
local notify = require "notify"
local M = {}

local function in_compare_mode(normal_windows)
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

local function cmp_two_bufs()
  vim.t.ca_cmp_bufs = fn.only_normal_windows()

  --- winnr() checks the number of wins IN A TAB.
  if vim.fn.winnr() == 2 then
    --- Ensure the 2nd win is on the right.
    vim.cmd "wincmd L"
  end

  local back_to_wid = vim.fn.win_getid()
  --- ':windo' doesn't suit because of floating wins.
  for _, wid in pairs(vim.t.ca_cmp_bufs) do
    vim.fn.win_gotoid(wid)
    vim.cmd ":diffthis"
  end

  vim.fn.win_gotoid(back_to_wid)
  --- Remove notifications wins.
  if notify ~= nil then
    --- Don't try to remove them before you have drawn them.
    vim.defer_fn(function()
      notify.dismiss()
    end, 100)
  end
  --- After switching between wins, notifications about changing the root
  --- directory might appear (if the project.nvim option 'silent_chdir' is
  --- set to false). Note: removing them with the command above is
  --- a bit overkill.
end

local function stop_cmp_bufs()
  local back_to_wid = vim.fn.win_getid()

  vim.cmd ":diffoff"
  vim.t.ca_cmp_bufs = nil

  vim.fn.win_gotoid(back_to_wid)

  if notify ~= nil then
    vim.schedule(notify.dismiss)
  end
end

function M.cmp_buffs_toggle()
  local normal_windows = fn.only_normal_windows()
  print(vim.inspect(normal_windows))

  if #normal_windows ~= 2 then
    return {}
  end

  if in_compare_mode(normal_windows) then
    return stop_cmp_bufs()
  else
    return cmp_two_bufs()
  end

  --- If registering as code actions.
  -- if in_compare_mode(normal_windows) then
  --   return { action = stop_cmp_bufs, title = "Stop comparing" }
  -- else
  --   return { action = cmp_two_bufs, title = "Compare buffers" }
  -- end
end

return M
