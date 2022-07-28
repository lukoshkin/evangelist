local keymap = require'lib.utils'.keymap

require'nvim-tree'.setup {
  update_focused_file = {
    enable = true,
    update_cwd = true,
    ignore_list = {},
  },
  renderer = {
    highlight_opened_files = 'icon',
    group_empty = true,
  },
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

keymap('n', '<Leader>nt', ':NvimTreeToggle<CR>')
keymap('n', '<Leader>nf', ':NvimTreeFindFileToggle<CR>')

vim.cmd[[
  autocmd BufEnter * ++nested
  \ if winnr('$') == 1 && bufname() == 'NvimTree_' . tabpagenr()
  \| quit
  \| endif
]]
