vim.g.maplocalleader = ' '
--- Syntax highlighting for embeded code (e.g., in vim.cmd[[]])
vim.g.vimsyn_embed = 'lP'
vim.g.winbar_first_sep = ' 〉'

local options = {
  cursorline = true,
  colorcolumn = '80',
  signcolumn = 'yes:2',

  title = true,
  number = true,
  confirm = true,
  relativenumber = true,
  termguicolors = true,

  tabstop = 2,
  softtabstop = 2,
  shiftwidth = 2,
  expandtab = true,
  smartindent = true,
  foldenable = false,
  foldlevel = 2,

  ignorecase = true,
  smartcase = true,
  lazyredraw = true,
  updatetime = 250,

  --- The mouse is turned off by default.
  mouse = "",

  --- completeopt is relevant for standard Vim menu
  --- and won't work if the latter is overriden by a plugin.
  completeopt = 'menuone,longest,preview',

  showmode = false, -- don't show --INSERT-- and etc.
  wildmode = 'longest:full,full', -- modes for cmd line completion.

  splitright = true,
  splitbelow = true,

  undofile = true,
  backup = true,
  writebackup = true,

  --- Defaults in recent Neovim versions.
  directory = vim.fn.stdpath 'state' .. '/swap//',
  backupdir = vim.fn.stdpath 'state' .. '/backup//',
  undodir = vim.fn.stdpath 'state' .. '/undo//',
  --- '//' at the end tells vim to use absolute file paths
  --- (when saving swap, undo, or backup files) to avoide name collisions.
}

for k, v in pairs(options) do
  vim.opt[k] = v
end


--- ru2en mapping in all modes but insert.
--- Change the symbols inserted (ru or en) with <C-^>.
--- A good alternative would be 'lyokha/vim-xkbswitch' plugin.
vim.opt.keymap = 'russian-jcukenwin'
--- Start from 'en' (since we've changed defaults on the line above).
vim.opt.iminsert = 0
vim.opt.imsearch = 0
