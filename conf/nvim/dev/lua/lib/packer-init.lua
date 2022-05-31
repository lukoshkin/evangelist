local packer = require 'packer'

packer.init {
  display = {
    open_fn = function ()
      return require('packer.util').float {
        border = 'rounded'
      }
    end,
  },
}

local aug = vim.api.nvim_create_augroup('PackerUserConfig', {clear=true})
local conf_path = vim.fn.stdpath 'config' .. '/lua/user/'
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = conf_path .. '*.lua',
  command = 'source <afile> | PackerCompile',
  group = aug
})

return packer
