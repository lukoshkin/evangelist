local conform = require "conform"
local config_path = vim.fn.stdpath "config" .. "/stylua.toml"

---@param bufnr integer | nil
---@param ... string
---@return string | table
local function first(bufnr, ...)
  if bufnr == nil then
    return { ... }
  end

  for i = 1, select("#", ...) do
    local formatter = select(i, ...)
    if conform.get_formatter_info(formatter, bufnr).available then
      return formatter
    end
  end
  return select(1, ...)
end

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
    javascript = { "prettierd", "prettier", stop_after_first = true },
    yaml = function(bufnr)
      return { first(bufnr, "prettierd", "prettier"), "yamlfix" }
    end,
    json = function(bufnr)
      return { first(bufnr, "prettierd", "prettier"), "fixjson" }
    end,
    markdown = function(bufnr)
      return { first(bufnr, "prettierd", "prettier"), "markdownlint" }
    end,
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
