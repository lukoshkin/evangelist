-- C/C++: clangd configuration
vim.lsp.config("clangd", {
  cmd = { "clangd", "--background-index", "--clang-tidy" }, -- enable background indexing and clang-tidy diagnostics
  filetypes = { "c", "cpp", "objc", "objcpp" },
  root_markers = {
    ".clangd",
    "compile_commands.json",
    "compile_flags.txt",
    ".git",
  },
  -- You can add capabilities like offsetEncoding if needed. Neovim 0.11 uses UTF-16 by default,
  -- so clangd works out-of-the-box. (If using clangd >=15 which defaults to UTF-8, you might add
  -- `capabilities = { offsetEncoding = { "utf-16" } }` to avoid any offset mismatch.)
})

-- Bash/Shell: bash-language-server (bashls)
vim.lsp.config("bashls", {
  cmd = { "bash-language-server", "start" },
  filetypes = { "sh", "bash" },
  root_markers = { ".git" },
  single_file_support = true, -- allow standalone script files to start the server
  settings = {
    bashIde = {
      -- Limit glob pattern for workspace scanning (to avoid scanning entire home dir)
      globPattern = vim.env.GLOB_PATTERN or "*@(.sh|.inc|.bash|.command)",
    },
  },
})

-- Dockerfile: dockerls (Docker language server)
vim.lsp.config("dockerls", {
  cmd = { "docker-langserver", "--stdio" },
  filetypes = { "dockerfile" },
  root_markers = { "Dockerfile", ".git" },
  single_file_support = true,
})

-- JSON: jsonls (VSCode JSON language server)
vim.lsp.config("jsonls", {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  root_markers = { ".git" },
  -- You can specify JSON schemas via settings if needed:
  -- settings = { json = { schemas = {...} } }
})

-- Markdown: marksman (Markdown LSP)
vim.lsp.config("marksman", {
  cmd = { "marksman", "server" },
  filetypes = { "markdown", "markdown.mdx" },
  root_markers = { ".marksman.toml", ".git" },
  single_file_support = true,
})

-- Rust: rust_analyzer (with Clippy on save)
vim.lsp.config("rust_analyzer", {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "Cargo.toml", "rust-project.json", ".git" },
  settings = {
    ["rust-analyzer"] = {
      -- Run `cargo clippy` on save to get Clippy lints&#8203;:contentReference[oaicite:6]{index=6}
      checkOnSave = { command = "clippy" },
    },
  },
})

-- Python: pylsp (Python LSP server) with Jedi & Rope rename support
vim.lsp.config("pylsp", {
  cmd = { "pylsp" },
  filetypes = { "python" },
  root_markers = {
    "pyproject.toml",
    "setup.cfg",
    "setup.py",
    "requirements.txt",
    ".git",
  },
  single_file_support = true,
  settings = {
    pylsp = {
      plugins = {
        jedi_rename = { enabled = true },
        rope_rename = { enabled = true },
        -- (Make sure you have the `pylsp-rope` plugin installed in Python for Rope features)
      },
    },
  },
})

-- Lua: lua_ls (Lua Language Server) for Neovim config and general Lua
vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  -- Neovim will automatically find the root by searching for .luarc.json, .git, etc.,
  -- but we can specify common markers:
  root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" }, -- Use Neovim's LuaJIT
      diagnostics = { globals = { "vim" } }, -- Recognize the `vim` global
      workspace = { checkThirdParty = false }, -- Don't prompt for third-party library approval&#8203;:contentReference[oaicite:7]{index=7}
      telemetry = { enable = false }, -- Disable telemetry&#8203;:contentReference[oaicite:8]{index=8}
    },
  },
})

-- **Optional**: TypeScript/JavaScript: tsserver (TypeScript Language Server)
vim.lsp.config("tsserver", {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = {
    "typescript",
    "typescriptreact",
    "typescript.tsx",
    "javascript",
    "javascriptreact",
    "javascript.jsx",
  },
  root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
  single_file_support = false, -- (tsserver usually expects a project context)
  -- Note: formatting is disabled globally, so tsserver won't format (you likely use eslint or prettier for that).
})

-- **Optional**: ESLint: eslint (for linting JavaScript/TypeScript)
vim.lsp.config("eslint", {
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
    -- ESlint config files and project indicators:
    ".eslintrc",
    ".eslintrc.json",
    ".eslintrc.js",
    ".eslintrc.cjs",
    "eslint.config.js",
    "package.json",
    ".git",
  },
  settings = {
    -- We disable ESLint formatting via our on_attach (below), but ensure linting is enabled:
    codeActionOnSave = { enable = false }, -- don't auto-fix on save
    format = false, -- don't format (let external formatter handle it)
  },
})
-- Enable all the LSP servers we configured above
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
