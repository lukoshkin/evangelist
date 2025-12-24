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
lint.linters_by_ft = {
  python = { "mypy" },
  lua = { "luacheck" },
  cpp = { "cpplint" },
  sh = { "shellcheck" },
  dockerfile = { "hadolint" },
  markdown = { "markdownlint" }, -- 'write-good' should be installed manually
}

local aug_lint = api.nvim_create_augroup("Lint", { clear = true })
api.nvim_create_autocmd({
  "BufEnter",
  "BufWritePost",
  "InsertLeave",
}, {
  group = aug_lint,
  callback = function()
    -- os.execute "kill -9 $(pgrep -f shellcheck)"
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
