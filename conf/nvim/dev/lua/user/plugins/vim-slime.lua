vim.g.slime_target = "tmux"
vim.g.slime_paste_file = "/tmp/.slime_paste"
vim.g.slime_dont_ask_default = 1
vim.g.slime_default_config = {
  socket_name = "default",
  target_pane = "{top-right}"
}

--- To send just a line, use <C-c><C-c> (default mapping).
--- Send text delimited by #%% (emulation of cells) with <C-s>.
vim.g.slime_cell_delimiter = "#%%"
vim.keymap.set('n', '<leader><CR>', '<Plug>SlimeSendCell')
--- NOTE: <Plug>(SlimeSendCell) won't work here.
