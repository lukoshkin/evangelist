local layout_opts = {
  layout_config = {
    prompt_position = "top",
    preview_width = 80,
  },
  sorting_strategy = "ascending",
}

local function with_opts(opts)
  return vim.tbl_extend("force", layout_opts, opts or {})
end

return {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "AckslD/nvim-neoclip.lua",
    "rcarriga/nvim-notify",
    "nvim-telescope/telescope-project.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-telescope/telescope-live-grep-args.nvim",
    "debugloop/telescope-undo.nvim",
  },
  keys = {
    {
      "<Leader>ff",
      function()
        require("telescope.builtin").find_files(with_opts())
      end,
      desc = "Find files",
    },
    {
      "<Leader>fe",
      function()
        require("telescope.builtin").find_files(
          with_opts { fuzzy = false }
        )
      end,
      desc = "Find files (exact)",
    },
    {
      "<Leader>fa",
      function()
        require("telescope.builtin").find_files(
          with_opts { no_ignore = true, prompt_title = "All Files" }
        )
      end,
      desc = "Find all files",
    },
    {
      "<Leader>b",
      function()
        require("telescope.builtin").buffers(with_opts())
      end,
      desc = "Buffers",
    },
    {
      "<Leader>fg",
      function()
        require("telescope").extensions.live_grep_args
          .live_grep_args(with_opts())
      end,
      desc = "Live grep",
    },
    {
      "<Leader>fo",
      function()
        require("telescope.builtin").oldfiles(with_opts())
      end,
      desc = "Old files",
    },
    {
      "<Leader>fp",
      function()
        require("telescope").extensions.project.project(with_opts())
      end,
      desc = "Projects",
    },
    {
      "<Leader>fh",
      function()
        require("telescope.builtin").help_tags(with_opts())
      end,
      desc = "Help tags",
    },
    {
      "<Leader>fk",
      function()
        require("telescope.builtin").keymaps(with_opts())
      end,
      desc = "Keymaps",
    },
    { "<Leader>fn", "<cmd>Telescope notify<CR>", desc = "Notifications" },
    {
      "<Leader>fu",
      function()
        require("telescope").extensions.undo.undo(with_opts())
      end,
      desc = "Undo tree",
    },
    {
      "<Leader>fr",
      function()
        require("telescope.builtin").resume()
      end,
      desc = "Resume search",
    },
  },
  config = function()
    local actions = require "telescope.actions"
    local state = require "telescope.actions.state"
    local telescope = require "telescope"
    local lga_actions = require "telescope-live-grep-args.actions"

    local delete_buffer = function(prompt_bufnr)
      if state.get_selected_entry()[1] == nil then
        return actions.delete_buffer(prompt_bufnr)
      end
    end

    telescope.setup {
      defaults = {
        prompt_prefix = "  ",
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
        --- Note: it exploits Lua regex pattern.
        file_ignore_patterns = {
          ".git/",
          "/nvim/runtime/doc/.+%.txt",
          "/nvim/site/pack/packer/start/.+/doc/.+%.txt",
          --- The last two to hide Vim and Vim plugins help files.
        },
      },
      pickers = {
        find_files = { hidden = true },
        oldfiles = { prompt_title = "History" },
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case", -- or "ignore_case" or "respect_case"
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
          mappings = {
            n = {
              ["<C-r>"] = require("telescope-undo.actions").restore,
            },
          },
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

    telescope.load_extension "project"
    telescope.load_extension "neoclip"
    telescope.load_extension "notify"
    telescope.load_extension "undo"
  end,
}
