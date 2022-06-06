-- This setup is taken from:
-- https://alpha2phi.medium.com/neovim-for-beginners-lsp-using-null-ls-nvim-bd954bf86b40
local nls = require'null-ls'
local nls_utils = require'null-ls.utils'
local b_ins = nls.builtins

local with_diagnostics_code = function(builtin)
  return builtin.with {
    diagnostics_format = "#{m} [#{c}]",
  }
end

local with_root_file = function(builtin, file)
  return builtin.with {
    condition = function(utils)
      return utils.root_has_file(file)
    end,
  }
end

local sources = {
  -- formatting
  b_ins.formatting.prettierd,
  b_ins.formatting.shfmt,
  b_ins.formatting.fixjson,
  b_ins.formatting.black.with { extra_args = { "--fast" } },
  b_ins.formatting.isort,
  with_root_file(b_ins.formatting.stylua, "stylua.toml"),

  -- diagnostics
  b_ins.diagnostics.write_good,
  b_ins.diagnostics.flake8,
  b_ins.diagnostics.pylint,
  with_root_file(b_ins.diagnostics.selene, "selene.toml"),
  with_diagnostics_code(b_ins.diagnostics.shellcheck),

  -- code actions
  b_ins.code_actions.gitsigns,
  b_ins.code_actions.gitrebase,

  -- hover
  b_ins.hover.dictionary,
}

nls.setup {
  -- debug = true,
  -- debounce = 150,
  save_after_format = false,
  sources = sources,
  -- on_attach = opts.on_attach,
  root_dir = nls_utils.root_pattern ".git",
}
