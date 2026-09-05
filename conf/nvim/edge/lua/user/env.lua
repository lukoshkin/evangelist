if vim.env.VIM_AWS_PROFILE then
  vim.env.AWS_PROFILE = vim.env.VIM_AWS_PROFILE
end

--- Set NVIM_MINIMAL=1 to skip Mason, treesitter parser auto-install, UI
--- chrome (bufferline/lualine/notify), and Copilot, for a lighter startup
--- on weak/remote hosts. Keymaps and options are unaffected.
vim.g.nvim_minimal = vim.env.NVIM_MINIMAL == "1"

--- Set NVIM_MINIMAL_PYLSP=1 to make the Mason-installed basedpyright
--- binary reachable for Python go-to-definition/hover, without pulling
--- in mason.nvim or any other mason-installed server. Independent of
--- NVIM_MINIMAL -- toggle separately.
vim.g.nvim_minimal_pylsp = vim.env.NVIM_MINIMAL_PYLSP == "1"

--- Set NVIM_MINIMAL_PYTS=1 to still install the Python treesitter parser
--- under NVIM_MINIMAL, so plugins that parse Python (e.g. pymove.nvim)
--- keep working. Independent of NVIM_MINIMAL_PYLSP -- toggle separately.
vim.g.nvim_minimal_pyts = vim.env.NVIM_MINIMAL_PYTS == "1"
