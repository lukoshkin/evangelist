local packer = require'packer'

packer.init {
  display = {
    open_fn = function ()
      return require'packer.util'.float {
        border = 'rounded'
      }
    end,
  },
}

local aug = vim.api.nvim_create_augroup('PackerUserConfig', {clear=true})
local plugins = vim.fn.stdpath'data' .. '/site/pack/packer/'
local configs = vim.fn.stdpath'config' .. '/lua/user/'

vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = { configs .. '*.lua', plugins .. '*.lua' },
  command = 'source <afile> | PackerCompile',
  group = aug
})

return packer
