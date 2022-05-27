vim.g.lion_squeeze_spaces = 1

local toggle_squeeze = function ()
  if vim.g.lion_squeeze_spaces == 0 then
    vim.g.lion_squeeze_spaces = 1
  else
    vim.g.lion_squeeze_spaces = 0
  end
end

vim.keymap.set({'n', 'x'}, 'glg', toggle_squeeze)
