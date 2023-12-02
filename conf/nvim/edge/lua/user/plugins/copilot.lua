--- Maybe it is a good idea to use copilot.lua instead?
local api = vim.api
local fn = vim.fn

local keymap = require("lib.utils").keymap
vim.g.copilot_no_tab_map = true
vim.g.copilot_preword_space = ""

keymap("i", "<C-j>", "copilot#Accept('<CR>')", {
  expr = true,
  replace_keycodes = false,
})


local function accept_word()
  fn["copilot#Accept"]()
  local bar = fn["copilot#TextQueuedForInsertion"]()

  local line = bar:match "^[^\n]*" or ""
  local preword_space = vim.g.copilot_preword_space or ""
  local word = preword_space .. (line:match "%S+" or "")
  vim.g.copilot_preword_space = line:sub(#word + 1):match "^%s*"
  --- NOTE: that moving cursor manually will result in a wrong
  --- value of `vim.g.copilot_preword_space`

  if word == "" then
    vim.schedule(function()
      vim.notify(
        " Use <C-l> to accept a line or just hit <Enter>",
        vim.log.levels.INFO,
        { title = "evn-settings" }
      )
    end)
  end
  return word
end


local function accept_line()
  fn["copilot#Accept"]()
  local bar = fn["copilot#TextQueuedForInsertion"]()
  local line = bar:match "^[^\n]*"
  local par_id = bar:find "\n\n"

  if #bar > #line then
    line = line .. "\n"
  end

  if par_id ~= nil and par_id == #line then
    line = bar:match "^[^\n]*\n\n%s*"
    api.nvim_command "set paste"
    vim.defer_fn(function()
      api.nvim_command "set nopaste"
    end, 10)
  end
  return line
end


keymap("i", "<C-w>", accept_word, { expr = true, remap = false })
keymap("i", "<C-l>", accept_line, { expr = true, remap = false })

--- Not sure the following is usable. I didn't test it.
keymap("i", "<C-p>", "copilot#Previous()", { expr = true })
keymap("i", "<C-n>", "copilot#Next()", { expr = true })
