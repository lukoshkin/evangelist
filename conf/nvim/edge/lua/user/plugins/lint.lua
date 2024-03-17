local lint = require "lint"
local api = vim.api

lint.linters.flake8.args = {
  --- Ignore flake8's complaints about:
  --- * `##` and `#<not_whitespace_char>`
  --- * line break before a binary operator
  "--ignore=E265,E266,W503",
  "--max-line-length=80",
}
lint.linters.luacheck.args = {
  "--globals",
  "vim",
}

lint.linters_by_ft = {
  python = { "flake8", "pylint", "mypy" },
  -- rust = { "rust-analyzer" },  -- Should be installed manually
  lua = { "luacheck" },
  cpp = { "cpplint" },
  sh = { "shellcheck" },
  dockerfile = { "hadolint" },
  markdown = { "markdownlint" },  -- 'write-good' should be installed manually
}

local aug_lint = api.nvim_create_augroup("Lint", { clear = true })
api.nvim_create_autocmd({
  "BufEnter",
  "BufWritePost",
  "InsertLeave",
  "TextChanged",
}, {
  group = aug_lint,
  callback = function()
    lint.try_lint()
    if
      api.nvim_win_get_config(0).relative == ""
      and vim.opt.modifiable:get()
      and vim.opt.buftype:get() == ""
      and vim.opt.filetype:get() ~= ""
    then
      lint.try_lint "cspell"
    end
  end,
})
