vim.opt.foldcolumn = "1"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

local aug = vim.api.nvim_create_augroup("UserFolding", { clear = true })

local function set_lsp_folds()
  vim.wo.foldmethod = "expr"
  vim.wo.foldexpr = "v:lua.vim.lsp.foldexpr()"
end

local function set_ts_folds()
  vim.wo.foldmethod = "expr"
  vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
end

local function set_indent_folds()
  vim.wo.foldmethod = "indent"
  vim.wo.foldlevel = 99
end

local function buf_has_lsp_folding(buf)
  for _, c in ipairs(vim.lsp.get_clients { bufnr = buf }) do
    if
      c.server_capabilities and c.server_capabilities.foldingRangeProvider
    then
      return true
    end
  end
  return false
end

vim.api.nvim_create_autocmd("FileType", {
  group = aug,
  callback = function(ev)
    local buf = ev.buf
    local ft = vim.bo[buf].filetype
    local bt = vim.bo[buf].buftype

    if bt == "nofile" or bt == "prompt" or bt == "help" then
      return
    end

    if ft == "yaml" or ft == "yml" then
      set_indent_folds()
      return
    end

    if buf_has_lsp_folding(buf) then
      set_lsp_folds()
      return
    end

    local ok = pcall(set_ts_folds)
    if not ok then
      set_indent_folds()
    end
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = aug,
  callback = function(args)
    local buf = args.buf
    local ft = vim.bo[buf].filetype
    if ft == "yaml" or ft == "yml" then
      return
    end

    if buf_has_lsp_folding(buf) then
      set_lsp_folds()
      return
    end

    local ok = pcall(set_ts_folds)
    if not ok then
      set_indent_folds()
    end
  end,
})
