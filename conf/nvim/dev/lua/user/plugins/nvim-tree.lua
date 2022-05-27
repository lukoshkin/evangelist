vim.g.nvim_tree_highlight_opened_files = 1
vim.g.nvim_tree_group_empty = 1

require'nvim-tree'.setup {
  view = {
    mappings = {
      list = {
        { key = 't',                action = 'tabnew' },
        { key = '<C-s>',            action = 'split' },
        { key = {'go', '<Tab>'},    action = 'preview' },
        { key = '?',                action = 'toggle_help' },
        { key = 'h',                action = 'toggle_dotfiles' },
        { key = 'r',                action = 'refresh' },
        { key = 'R',                action = 'rename' },
        { key = 'I',                action = 'toggle_git_ignored' },
        { key = 'd',                action = 'trash' },
        { key = 'D',                action = 'remove' },
      }
    }
  }
}

vim.keymap.set('n', '<leader>nt', ':NvimTreeToggle<CR>')
vim.keymap.set('n', '<leader>nf', ':NvimTreeFindFileToggle<CR>')

vim.cmd[[
  autocmd BufEnter * ++nested
  \ if winnr('$') == 1 && bufname() == 'NvimTree_' . tabpagenr()
  \| quit
  \| endif
]]
