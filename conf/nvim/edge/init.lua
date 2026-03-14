local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  }
end

vim.opt.rtp:prepend(lazypath)

require "user.env"

vim.g.maplocalleader = " "

require("lazy").setup {
  { import = "user.core" },
  { import = "user.appearance" },
  { import = "user.ide" },
  { import = "user.editing" },
  { import = "user.ai" },
  { import = "user.ft" },
  { import = "user.git" },
}

require "user.mappings"
require "user.lspconfig"
require "user.options"
require "user.folding"
