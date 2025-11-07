local config = require "move.config"
local move = require "move"

-- Create user commands
vim.api.nvim_create_user_command("PySortClass", function()
  move.sort_class()
end, {
  desc = "Sort methods in Python class at cursor",
})

vim.api.nvim_create_user_command("PySortFile", function()
  move.sort_file()
end, {
  desc = "Sort all functions and methods in Python file",
})

vim.api.nvim_create_user_command("PySortMethods", function(opts)
  local scope = opts.args
  if scope == "" then
    scope = "class"
  end
  move.sort_python(scope)
end, {
  nargs = "?",
  complete = function()
    return { "visual", "class", "file" }
  end,
  desc = "Sort Python functions/methods with scope (visual|class|file)",
})

-- Setup default keymaps if enabled
if config.options.default_keymaps then
  vim.keymap.set("n", "<Space>mc", function()
    move.sort_class()
  end, {
    desc = "Sort methods in current Python class",
    buffer = false,
  })

  vim.keymap.set("n", "<Space>mm", function()
    move.sort_file()
  end, {
    desc = "Sort all functions/methods in Python file",
    buffer = false,
  })

  vim.keymap.set("v", "<Space>m", function()
    move.sort_visual()
  end, {
    desc = "Sort Python functions/methods in selection",
    buffer = false,
  })
end
