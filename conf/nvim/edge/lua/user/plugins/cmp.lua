local cmp = require 'cmp'
local luasnip = require 'luasnip'
local lspkind = require 'lspkind'

--- Load snippets from 'rafamadriz/friendly-snippets'.
require'luasnip.loaders.from_vscode'.lazy_load()


--- Check if there is no space before the cursor.
local is_completable = function()
  local col = vim.fn.col '.' - 1
  local char = vim.fn.getline('.'):sub(col, col)
  return col ~= 0 and char:match '%s' == nil
end

cmp.setup {
  -- experimental = {
  --- the most relevant suggestion appears on the line
  --- with the cursor in the form of grayed out virtual text.
  --   ghost_text = true,
  -- },
  formatting = {
    --- How completion menu looks.
    format = lspkind.cmp_format {
      with_text = false,
      --- Don't write the type of completion, just show the icon.
      --- [function ()~  (LSP)] instead of [function ()~  Snippet (LSP)].
      menu = {
        --- How sources names look in completion menu.
        luasnip = '(Snippet)',
        nvim_lsp = '(LSP)',
        cmp_tabnine = '(Tabnine)',
        path = '(Path)',
        buffer = '(Buffer)',
        treesitter = '(Treesitter)',
        nvim_lua = '(Lua)',
      },
    },
  },
  snippet = {
  --- How cmp interacts with snippet engine.
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  mapping = {
    --- Override Vim completion (triggered by <C-n/p>) menu with that of cmp.
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    --- Initiate completion w/o any text provided.
    ['<C-Space>'] = cmp.mapping.complete(), -- same as `cmp.complete()`
    --- Close and restore original (abort) and just close (close) mappings.
    ['<C-e>'] = cmp.mapping.abort(),
    ['<S-A-e>'] = cmp.mapping.close(), -- TODO: set completed_successfully to true.

    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),

    --- TODO: set or declare `b:completed_successfully` to true
    ['<CR>'] = cmp.mapping.confirm {
      --- If there is text after the cursor, replace it
      --- with the selected option on the confirmation.
      behavior = cmp.ConfirmBehavior.Replace, -- or Insert
      select = false,
      --- if true, hitting enter w/o any item selected
      --- will complete to the first option.
    },

    ['<Tab>'] = cmp.mapping(function(fallback)
      --- First, select the next item in the menu, if it is open.
      --- Then, jump with tab to a potential next place
      --- in a snippet (or expand a snippet component);
      --- If neither of the two actions is possible ─
      --- initiate completion (e.g. re-initiate after confirmation).
      if cmp.visible() then
        cmp.select_next_item { behavior = cmp.SelectBehavior.Insert }
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
        --- TODO: set `b:completed_successfully` to false
      elseif is_completable() then
        cmp.complete()
        --- TODO: trim trailing whitespace if need be.
      else
        fallback()
      end
    end, { 'i', 's' }),

    ['<S-Tab>'] = cmp.mapping(function(fallback)
      --- When moving back, we give the same preference order to items
      --- selection in completion menu and hops within the snippet. However,
      --- we don't need to expand anything when moving back, since it had
      --- been expanded during direct passage.
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        if vim.fn.col '.' ~= 1 and not is_completable() then
          --- not is_completable --> col '.' == 1 or prev_char == ' '
          vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes(
              '<BS>', true, true, true), 'i', true)
        end
      end
    end, { 'i', 's' }),
  },
  sources = {
  --- for completion options (corresponding plugins should be installed).
    --- Order matters.
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'cmp_tabnine' },
    { name = 'path' },
    { name = 'buffer' },
    { name = 'treesitter' },
    { name = 'nvim_lua' },
    { name = 'nvim_lsp_signature_help' },
    -- { name = 'digraphs' },
  },
}
