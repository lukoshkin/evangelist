--- Maybe it is a good idea to use copilot.lua instead?
local keymap = require("lib.utils").keymap
vim.g.copilot_no_tab_map = true

keymap("i", "<C-j>", "copilot#Accept('<CR>')", {
  expr = true,
  replace_keycodes = false,
})

local function accept_word()
  vim.fn['copilot#Accept']("")
  local bar = vim.fn['copilot#TextQueuedForInsertion']()
  return vim.fn.split(bar, [[\([ .]\|\n\s*\)\zs]])[1]
end


local function accept_line()
  vim.fn['copilot#Accept']("")
  local bar = vim.fn['copilot#TextQueuedForInsertion']()
  return vim.fn.split(bar, [[\n\s*\zs]])[1]
end


keymap('i', '<C-w>', accept_word, { expr = true, remap = false })
keymap('i', '<C-l>', accept_line, { expr = true, remap = false })

--- Not sure the following is usable. I didn't test it.
keymap("i", "<C-p>", "copilot#Previous()", { expr = true })
keymap("i", "<C-n>", "copilot#Next()", { expr = true })
