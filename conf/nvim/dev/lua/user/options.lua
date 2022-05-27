--- Syntax highlighting for embeded code (e.g., in vim.cmd[[]])
vim.g.vimsyn_embed = 'lP'

local options = {
  cursorline = true,
  colorcolumn = '80',
  signcolumn = 'yes:2',

  title = true,
  number = true,
  relativenumber = true,
  termguicolors = true,

  tabstop = 2,
  softtabstop = 2,
  shiftwidth = 2,
  expandtab = true,
  smartindent = true,
  foldlevel = 2,

  ignorecase = true,
  smartcase = true,
  lazyredraw = true,

  --- completeopt is relevant for standard Vim menu
  --- and won't work if the latter is overriden by a plugin.
  completeopt = 'menuone,longest,preview',

  showmode = false, -- don't show --INSERT-- and etc.
  wildmode = 'longest:full,full', -- modes for cmd line completion.

  wrap = false,
  confirm = true,

  splitright = true,
  splitbelow = true,

  undofile = true,
  directory = vim.fn.stdpath 'data' .. '/swap//',
}

for k, v in pairs(options) do
  vim.opt[k] = v
end
