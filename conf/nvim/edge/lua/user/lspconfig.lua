vim.lsp.config("*", {
  capabilities = {
    textDocument = {
      semanticTokens = {
        multilineTokenSupport = true,
      },
    },
  },
  root_markers = { ".git" },
})
vim.lsp.config.pylsp = {
  cmd = { "pylsp" },
  filetypes = { "python" },
  root_markers = {
    "pyproject.toml",
    "setup.cfg",
    "requirements.txt",
  },
  single_file_support = true,
  settings = {
    pylsp = {
      plugins = {
        jedi_rename = { enabled = true },
        rope_rename = { enabled = true },
        -- (Make sure `pylsp-rope` plugin is installed in Python for Rope use)
      },
    },
  },
}
--- Add clippy linting (includes performance hints).
vim.lsp.config.rust_analyzer = {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "Cargo.toml", "rust-project.json" },
  settings = {
    ["rust-analyzer"] = {
      checkOnSave = {
        allFeatures = true,
        overrideCommand = {
          "cargo",
          "clippy",
          "--workspace",
          "--message-format=json",
          "--all-targets",
          "--all-features",
        },
      },
    },
  },
}
vim.lsp.config.bashls = {
  cmd = { "bash-language-server", "start" },
  filetypes = { "sh", "bash" },
  root_markers = { ".git" },
  single_file_support = true,
  settings = {
    bashIde = {
      -- Limit glob pattern for workspace scanning
      globPattern = vim.env.GLOB_PATTERN or "*@(.sh|.inc|.bash|.command)",
    },
  },
}
vim.lsp.config.clangd = {
  cmd = {
    "clangd",
    "--clang-tidy",
    "--background-index",
    "--offset-encoding=utf-8",
  },
  root_markers = { ".clangd", "compile_commands.json" },
  filetypes = { "c", "cpp" },
}
local runtime_path = vim.split(package.path, ";")
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")
vim.lsp.config.lua_ls = {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc" },
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      runtime = { version = "LuaJIT", path = runtime_path },
    },
    workspace = { library = vim.api.nvim_get_runtime_file("", true) },
    telemetry = { enable = false },
  },
}
vim.lsp.config.dockerls = {
  cmd = { "docker-langserver", "--stdio" },
  filetypes = { "dockerfile" },
  root_markers = { "Dockerfile" },
  single_file_support = true,
}
vim.lsp.config.marksman = {
  cmd = { "marksman", "server" },
  filetypes = { "markdown", "markdown.mdx" },
  root_markers = { ".marksman.toml" },
  single_file_support = true,
}
vim.lsp.config.jsonls = {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  -- One can specify JSON schemas via settings if needed:
  -- settings = { json = { schemas = {...} } }
}
vim.lsp.config(
  "tsserver",
  { -- TypeScript/JavaScript: tsserver (TypeScript Language Server)
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = {
      "typescript",
      "typescriptreact",
      "typescript.tsx",
      "javascript",
      "javascriptreact",
      "javascript.jsx",
    },
    root_markers = { "package.json", "tsconfig.json", "jsconfig.json" },
    single_file_support = false, -- (tsserver usually expects a project context)
    -- Note: formatting is disabled globally, so tsserver won't format (you likely use eslint or prettier for that).
  }
)
vim.lsp.config("eslint", { -- eslint (for linting JavaScript/TypeScript)
  cmd = { "vscode-eslint-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
    "vue",
    "svelte",
  },
  root_markers = {
    ".eslintrc",
    ".eslintrc.json",
    ".eslintrc.js",
    ".eslintrc.cjs",
    "eslint.config.js",
    "package.json",
  },
  settings = {
    -- We disable ESLint formatting via our on_attach (below), but ensure linting is enabled:
    codeActionOnSave = { enable = false }, -- don't auto-fix on save
    format = false, -- don't format (let external formatter handle it)
  },
})

local function on_attach(ev)
  local client = vim.lsp.get_client_by_id(ev.data.client_id)
  if client == nil then
    return
  end

  local ok_navic, navic = pcall(require, "nvim-navic")
  if ok_navic and client.server_capabilities.documentSymbolProvider then
    navic.attach(client, ev.buf)
  end
  --- Currently, completion is configured by 'nvim-cmp'.
  -- if client.supports_method("textDocument/completion", ev.buf) then
  --   vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
  -- end
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    on_attach(ev)
    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local buf_keymap = require("lib.utils").buf_keymap
    buf_keymap(ev.buf, "n", "gD", vim.lsp.buf.declaration)
    buf_keymap(ev.buf, "n", "gd", vim.lsp.buf.definition)
    buf_keymap(ev.buf, "n", "K", vim.lsp.buf.hover)
    buf_keymap(ev.buf, "n", "gs", vim.lsp.buf.signature_help)
    buf_keymap(ev.buf, "n", "<Leader>td", vim.lsp.buf.type_definition)
    buf_keymap(ev.buf, "n", "<Leader>rn", vim.lsp.buf.rename)
    buf_keymap(ev.buf, "n", "gr", ":Telescope lsp_references<CR>")
    --- gi and gI are reserved by original Vim command (see :h gi, e.g.).
    buf_keymap(ev.buf, "n", "<Leader>i", vim.lsp.buf.implementation)

    --- A standard lsp approach would be
    --- vim.lsp.buf.xxx_action()
    ---               or
    --- ':Telescope lsp_xxx_actions<CR>'
    --- where 'xxx' is 'code' or 'range_code'.

    --- 'ge' like (E)xplain (E)rror.
    buf_keymap(ev.buf, "n", "ge", vim.diagnostic.open_float)
    --- ][d for looping over all diagnostic messages.
    buf_keymap(ev.buf, "n", "[d", function()
      vim.diagnostic.jump {
        count = -1,
        severity = { min = vim.diagnostic.severity.INFO },
      }
    end)
    buf_keymap(ev.buf, "n", "]d", function()
      vim.diagnostic.jump {
        count = 1,
        severity = { min = vim.diagnostic.severity.INFO },
      }
    end)
    --- ][e ─ over just error messages.
    buf_keymap(ev.buf, "n", "[e", function()
      vim.diagnostic.jump {
        count = -1,
        severity = vim.diagnostic.severity.ERROR,
      }
    end)
    buf_keymap(ev.buf, "n", "]e", function()
      vim.diagnostic.jump {
        count = 1,
        severity = vim.diagnostic.severity.ERROR,
      }
    end)

    --- Open full diagnostics in location-list + find symbols(primitive data type) using telescope.
    buf_keymap(ev.buf, "n", "<Space>q", vim.diagnostic.setloclist)
    buf_keymap(
      ev.buf,
      "n",
      "<Leader>fs",
      require("telescope.builtin").lsp_document_symbols
    )

    --- NOTE: to format relying only on 'textwidth' use 'gw'.
  end,
})

vim.lsp.enable {
  "clangd",
  "bashls",
  "dockerls",
  "jsonls",
  "marksman",
  "rust_analyzer",
  "pylsp",
  "lua_ls",
  "tsserver",
  "eslint",
}
