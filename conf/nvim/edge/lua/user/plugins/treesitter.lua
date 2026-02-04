local api = vim.api
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    config = function() --- opts = {...} does not work for 'main' branch yet
      local ts = require "nvim-treesitter"
      ts.setup {
        install_dir = vim.fn.stdpath "data" .. "/site",
      }
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
