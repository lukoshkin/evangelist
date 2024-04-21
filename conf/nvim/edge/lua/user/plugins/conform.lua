local conform = require "conform"
local config_path = vim.fn.stdpath "config" .. "/stylua.toml"

conform.setup {
  formatters = {
    black = {
      prepend_args = {
        "--fast",
        "--line-length=79",
        "--preview",
      },
    },
    stylua = {
      prepend_args = {
        "--config-path=" .. config_path,
        "--column-width=80",
      },
    },
  },
  formatters_by_ft = {
    ["*"] = { "codespell" },
    lua = { "stylua" },
    python = { "isort", "black" },
    rust = { "rustfmt" },
    sh = { "shfmt" },
    yaml = { { "prettierd", "prettier" } },
    json = { { "prettierd", "prettier" }, "fixjson" },
    markdown = { { "prettierd", "prettier" }, "markdownlint" },
    cpp = { "clang-format" },
    c = { "clang-format" },
  },
}

--- TODO: Think about whether to move keymap definition to 'plugins.lua'.
--- The motive not to do so is that formatters are loaded not on a key press.
vim.keymap.set("", "<Leader>cf", function()
  conform.format {
    lsp_fallback = true,
    async = true,
    timeout = 500,
  }
end, { desc = "Format file or lines selection" })
