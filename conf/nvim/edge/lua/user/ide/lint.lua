return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require "lint"
    local api = vim.api

    lint.linters.luacheck.args = {
      "--globals",
      "vim",
    }
    lint.linters.cspell = require("lint.util").wrap(
      lint.linters.cspell,
      function(diagnostic)
        diagnostic.severity = vim.diagnostic.severity.HINT
        return diagnostic
      end
    )
    local all_linters_by_ft = {
      python = { "mypy" },
      lua = { "luacheck" },
      cpp = { "cpplint" },
      sh = { "shellcheck" },
      dockerfile = { "hadolint" },
      markdown = { "markdownlint" }, -- 'write-good' should be installed manually
    }

    --- nvim-lint ships defaults for many filetypes whose linters aren't in
    --- Mason's registry (inko, janet, ruby, clj-kondo, ...). Drop them so
    --- mason-nvim-lint only sees the linters we actually use and stops
    --- warning about the rest.
    lint.linters_by_ft = {}

    --- Filter out linters whose binaries are not installed.
    --- Mason (VeryLazy) may not have installed them yet on
    --- first buffer open.
    for ft, linter_list in pairs(all_linters_by_ft) do
      lint.linters_by_ft[ft] = vim.tbl_filter(function(name)
        return vim.fn.executable(name) == 1
      end, linter_list)
    end

    local aug_lint = api.nvim_create_augroup("Lint", { clear = true })
    api.nvim_create_autocmd({
      "BufEnter",
      "BufWritePost",
      "InsertLeave",
    }, {
      group = aug_lint,
      callback = function()
        lint.try_lint()
        if
          api.nvim_win_get_config(0).relative == ""
          and vim.opt.modifiable:get()
          and vim.opt.buftype:get() == ""
          and vim.opt.filetype:get() ~= ""
          and vim.fn.executable "cspell" == 1
        then
          lint.try_lint "cspell"
        end
      end,
    })
  end,
}
