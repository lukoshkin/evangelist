local telescope = require "telescope"
local actions = require "telescope.actions"
local state = require "telescope.actions.state"
local keymap = require("lib.utils").keymap

local lga_actions = require "telescope-live-grep-args.actions"

local delete_buffer = function(prompt_bufnr)
  if state.get_selected_entry()[1] == nil then
    return actions.delete_buffer(prompt_bufnr)
  end
end

telescope.setup {
  defaults = {
    prompt_prefix = "  ",
    selection_caret = "✎ ",
    -- path_display = { 'smart' },
    path_display = { truncate = 1 },
    --- if doesn't fit, truncate path keeping the gap
    --- between edge and text at specified size.
    mappings = {
      i = {
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-n>"] = actions.cycle_history_next,
        ["<C-p>"] = actions.cycle_history_prev,
        ["<C-s>"] = actions.file_split,
        ["<C-c>"] = actions.close,
        ["<C-h>"] = "which_key",
      },
      n = {
        ["q"] = actions.close,
        ["o"] = actions.file_edit,
        ["s"] = actions.file_split,
        ["v"] = actions.file_vsplit,
        ["d"] = delete_buffer,
        ["<C-h>"] = "which_key",
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-n>"] = actions.cycle_history_next,
        ["<C-p>"] = actions.cycle_history_prev,
      },
    },
    file_ignore_patterns = {
      --- Note: it exploits Lua regex pattern.
      ".git/",
      "/nvim/runtime/doc/.+%.txt",
      "/nvim/site/pack/packer/start/.+/doc/.+%.txt",
      --- The last two to hide Vim and Vim plugins help files.
    },
  },
  pickers = {
    find_files = {
      hidden = true,
    },
    oldfiles = {
      prompt_title = "History",
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case", --  or "ignore_case" or "respect_case"
                                --- the default case_mode is "smart_case"
    },
    live_grep_args = {
      mappings = {
        i = {
          ["<C-k>"] = actions.move_selection_previous,
          ["<A-'>"] = lga_actions.quote_prompt(),
        },
      },
    },
    undo = {
      entry_format = "#$ID, $STAT, $TIME",
      layout_config = {
        width = 0.95,
        preview_width = 0.8,
      },
      use_delta = true,
      side_by_side = true,
    },
  },
}

--- Telescope builds its own 'fzf' starting from some version.
-- require'telescope'.load_extension 'fzf'
require("telescope").load_extension "projects"
require("telescope").load_extension "neoclip"
require("telescope").load_extension "notify"
require("telescope").load_extension "undo"

--- Just a couple of shorthands.
local builtin = require "telescope.builtin"
local ext = telescope.extensions
local layout_opts = {
  layout_config = {
    prompt_position = "top",
    preview_width = 80,
  },
  sorting_strategy = "ascending",
}

local function _with_opts(fn, another_opts)
  return function()
    fn(vim.tbl_extend("force", layout_opts, another_opts or {}))
  end
end

--- Find files in the current directory (except hidden ones).
keymap("n", "<Leader>ff", _with_opts(builtin.find_files))

--- Find files exactly how the names are spelled.
keymap("n", "<Leader>fe", _with_opts(builtin.find_files, { fuzzy = false }))

--- All files not matched by `file_ignore_patterns`.
keymap(
  "n",
  "<Leader>fa",
  _with_opts(
    builtin.find_files,
    { no_ignore = true, prompt_title = "All Files" }
  )
)

--- Vim buffers ('bufferline' lists active buffers in the barline above).
keymap("n", "<Leader>b", _with_opts(builtin.buffers))

--- Find word. `live_grep_args` adds to `live_grep` allows to use regex
--- and pass CLI flags right from Telescope prompt.
keymap("n", "<Leader>fg", _with_opts(ext.live_grep_args.live_grep_args))

-- Find MRU files.
keymap("n", "<Leader>fo", _with_opts(builtin.oldfiles))

--- Find a project
keymap("n", "<Leader>fp", _with_opts(ext.projects.projects))

--- Request help using fuzzy search and preview.
keymap("n", "<Leader>fh", _with_opts(builtin.help_tags))

--- Find a key mapping.
keymap("n", "<Leader>fk", _with_opts(builtin.keymaps))

--- Find a key mapping.
keymap("n", "<Leader>fn", [[<cmd>Telescope notify<CR>]])

--- Find yanks made during the current session.
keymap("n", "<Leader>fy", _with_opts(ext.neoclip.neoclip))

--- Explore Vim's undo tree in a telescope window.
keymap("n", "<Leader>fu", _with_opts(ext.undo.undo))

--- Repeat regex search across the project.
keymap("n", "<Leader>fr", builtin.resume)
