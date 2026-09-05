local api = vim.api
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = not vim.g.nvim_minimal and ":TSUpdate" or false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    config = function() --- opts = {...} does not work for 'main' branch yet
      local ts = require "nvim-treesitter"
      ts.setup {
        install_dir = vim.fn.stdpath "data" .. "/site",
      }
      if not vim.g.nvim_minimal then
        ts.install {
          "c",
          "rust",
          "python",
          "javascript",
          "bash",
          "yaml",
          "vim",
          "lua",
          "dockerfile",
          "make",
          "cmake",
        }
      elseif vim.g.nvim_minimal_pyts then
        if vim.fn.executable "tree-sitter" == 0 then
          vim.notify(
            "NVIM_MINIMAL_PYTS is set but the `tree-sitter` CLI is missing"
              .. " from $PATH, so installing the Python parser here would"
              .. " just fail with a cryptic ENOENT. Options (review each"
              .. " before running -- don't pipe/copy blindly):\n"
              .. "  1) Install the tree-sitter CLI, e.g. from"
              .. " https://github.com/tree-sitter/tree-sitter/releases"
              .. " (verify the asset matches this host's OS/arch first),"
              .. " then reopen a Python file.\n"
              .. "  2) Copy an already-built parser.so from a host with a"
              .. " matching architecture to:\n"
              .. "     "
              .. vim.fn.stdpath "data"
              .. "/site/parser/python.so",
            vim.log.levels.WARN
          )
        else
          ts.install { "python" }
        end
      end
      local highlight_disable = {
        NvimTree = true,
        latex = true,
      }
      local indent_disable = {
        yaml = true,
        python = true,
      }
      api.nvim_create_autocmd("FileType", {
        group = api.nvim_create_augroup(
          "UserTreesitterMain",
          { clear = true }
        ),
        callback = function(ev)
          local buf = ev.buf
          local ft = vim.bo[buf].filetype

          --- Skip special buffers where TS + folds are noisy/useless
          local bt = vim.bo[buf].buftype
          if bt == "nofile" or bt == "prompt" or bt == "help" then
            return
          end

          if not highlight_disable[ft] then
            pcall(vim.treesitter.start, buf)
          end

          if not indent_disable[ft] then
            vim.bo[buf].indentexpr =
              "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
      --- YAML overrides
      api.nvim_create_autocmd("FileType", {
        group = api.nvim_create_augroup("YAMLIndentation", { clear = true }),
        pattern = { "yaml", "yml" },
        callback = function(ev)
          local buf = ev.buf
          vim.bo[buf].shiftwidth = 2
          vim.bo[buf].tabstop = 2
          vim.bo[buf].expandtab = true
          vim.bo[buf].indentexpr = ""
        end,
      })

      local ok_tobj, tobj = pcall(require, "nvim-treesitter-textobjects")
      if ok_tobj then
        tobj.setup {
          select = {
            enable = true,
            lookahead = true,
          },
        }
        local ok_sel, select =
          pcall(require, "nvim-treesitter-textobjects.select")
        if ok_sel then
          vim.keymap.set({ "x", "o" }, "af", function()
            select.select_textobject("@function.outer", "textobjects")
          end)
          vim.keymap.set({ "x", "o" }, "if", function()
            select.select_textobject("@function.inner", "textobjects")
          end)
          vim.keymap.set({ "x", "o" }, "ac", function()
            select.select_textobject("@class.outer", "textobjects")
          end)
          vim.keymap.set({ "x", "o" }, "ic", function()
            select.select_textobject("@class.inner", "textobjects")
          end)
          -- Conflict with mini.surround
          vim.keymap.set({ "x", "o" }, "av", function()
            select.select_textobject("@block.outer", "textobjects")
          end)
          vim.keymap.set({ "x", "o" }, "iv", function()
            select.select_textobject("@block.inner", "textobjects")
          end)
        end
      end
    end,
  },
}
