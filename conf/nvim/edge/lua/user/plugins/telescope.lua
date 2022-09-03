local telescope = require'telescope'
local actions = require'telescope.actions'
local state = require'telescope.actions.state'
local keymap = require'lib.utils'.keymap

local lga_actions = require"telescope-live-grep-args.actions"

local delete_buffer = function (prompt_bufnr)
  if state.get_selected_entry()[1] == nil then
    return actions.delete_buffer(prompt_bufnr)
  end
end

telescope.setup {
  defaults = {
    prompt_prefix = '  ',
    selection_caret = '🖉 ',
    -- path_display = { 'smart' },
    path_display = { truncate = 1 },
    --- if doesn't fit, truncate path keeping the gap
    --- between edge and text  at specified size.
    layout_config = {
      prompt_position = 'top',
      preview_width = 80,
    },

    sorting_strategy = 'ascending',
    mappings = {
      i = {
        ['<C-j>'] = actions.move_selection_next,
        ['<C-k>'] = actions.move_selection_previous,
        ['<C-n>'] = actions.cycle_history_next,
        ['<C-p>'] = actions.cycle_history_prev,
        ['<C-s>'] = actions.file_split,
        ['<C-c>'] = actions.close,
        ['<C-h>'] = 'which_key'
      },
      n = {
        ['q'] = actions.close,
        ['o'] = actions.file_edit,
        ['s'] = actions.file_split,
        ['v'] = actions.file_vsplit,
        ['d'] = delete_buffer,
        ['<C-h>'] = 'which_key',
        ['<C-j>'] = actions.move_selection_next,
        ['<C-k>'] = actions.move_selection_previous,
      }
    },
    file_ignore_patterns = {
      --- Note: it exploits Lua regex pattern.
      '.git/',
      '/nvim/runtime/doc/.+%.txt',
      '/nvim/site/pack/packer/start/.+/doc/.+%.txt',
      --- The last two to hide Vim and Vim plugins help files.
    },
  },
  pickers = {
    find_files = {
      hidden = true,
    },
    oldfiles = {
      prompt_title = 'History',
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = 'smart_case', --  or "ignore_case" or "respect_case"
                                --- the default case_mode is "smart_case"
    },
    live_grep_args = {
      mappings = {
        i = {
          ['<C-k>'] = actions.move_selection_previous,
          ["<A-'>"] = lga_actions.quote_prompt(),
        },
      },
    },
  },
}

require'telescope'.load_extension 'fzf'
require'telescope'.load_extension 'projects'
require'telescope'.load_extension 'neoclip'

--- Find files in the current directory (except hidden ones).
keymap('n', '<Leader>ff', [[<cmd>lua require'telescope.builtin'.find_files()<CR>]])
--- Find files exactly how the names are spelled.
keymap('n', '<Leader>fe', [[<cmd>lua require'telescope.builtin'.find_files({fuzzy = false})<CR>]])
--- All files not matched by `file_ignore_patterns`.
keymap('n', '<Leader>fa', [[<cmd>lua require'telescope.builtin'.find_files({ no_ignore = true, prompt_title = 'All Files' })<CR>]])
--- Vim buffers (thanks to bufferline plugin, open buffers are always listed above).
keymap('n', '<Leader>b', [[<cmd>lua require'telescope.builtin'.buffers()<CR>]])
--- Find word. `live_grep_args` adds to `live_grep` allows to use regex and pass CLI flags right from Telescope prompt.
keymap('n', '<Leader>fg', [[<cmd>lua require'telescope'.extensions.live_grep_args.live_grep_args()<CR>]])
-- Find MRU files.
keymap('n', '<Leader>fo', [[<cmd>lua require'telescope.builtin'.oldfiles()<CR>]])
--- Find a project
keymap('n', '<Leader>fp', [[<cmd>lua require'telescope'.extensions.projects.projects()<CR>]])
--- Request help using fuzzy search and preview.
keymap('n', '<Leader>fh', [[<cmd>Telescope help_tags<CR>]])
--- Find yanks made during the current session.
keymap( 'n', '<Leader>fy', [[<cmd> lua require'telescope'.extensions.neoclip.neoclip()<CR>]])
