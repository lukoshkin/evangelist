if vim.env.VIM_AWS_PROFILE then
  vim.env.AWS_PROFILE = vim.env.VIM_AWS_PROFILE
end

--- Set NVIM_MINIMAL=1 to skip Mason, treesitter parser auto-install, UI
--- chrome (bufferline/lualine/notify), and Copilot, for a lighter startup
--- on weak/remote hosts. Keymaps and options are unaffected.
vim.g.nvim_minimal = vim.env.NVIM_MINIMAL == "1"
