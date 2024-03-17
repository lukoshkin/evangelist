local keymap = require("lib.utils").keymap
local open = require("lib.utils")._opener
local fn = require "lib.function"
local misc = require "user.misc"
local api = vim.api

local aug_jj = api.nvim_create_augroup("EasierJJ", { clear = true })
api.nvim_create_autocmd("InsertEnter", {
  command = "set timeoutlen=200",
  group = aug_jj,
})

api.nvim_create_autocmd("InsertLeave", {
  command = "set timeoutlen=1000",
  group = aug_jj,
})

keymap("i", "jj", "<Esc>")

keymap("n", "<A-j>", "o<Esc>")
keymap("n", "<A-k>", "<S-o><Esc>")
keymap("n", "<A-h>", "i<Space><Esc>")
keymap("n", "<A-l>", "a<Space><Esc>")

keymap("n", "<S-A-j>", "o<Esc>k")
keymap("n", "<S-A-k>", "<S-o><Esc>j")
keymap("n", "<S-A-h>", "i<Space><Esc>l")
keymap("n", "<S-A-l>", "a<Space><Esc>h")

keymap({ "n", "i" }, "<A-m>", fn.toggle_mouse)

keymap("n", "<C-j>", ":m+1<CR>==")
keymap("n", "<C-k>", ":m-2<CR>==")
keymap("v", "<C-j>", ":m'>+<CR>gv=gv")
keymap("v", "<C-k>", ":m-2<CR>gv=gv")

keymap("n", "<C-Left>", function()
  fn.resize("-2", { vertical = true })
end)
keymap("n", "<C-Right>", function()
  fn.resize("+2", { vertical = true })
end)
keymap("n", "<C-Down>", function()
  fn.resize "-2"
end)
keymap("n", "<C-Up>", function()
  fn.resize "+2"
end)

--- Copy to clipboard selected text or the whole file.
keymap("x", "<Leader>y", '"+y')
keymap("n", "<Leader>y", ":%y+<CR>")

--- Change the terminal bg's transparency from within Vim
--- (valid only for Linux systems; maybe, just Ubuntu).
keymap("", "<A-+>", ":silent !transset -a --inc .02<CR>")
keymap("", "<A-->", ":silent !transset -a --dec .02<CR>")

--- Turn off highlighting and dismiss messages below the status bar.
keymap("n", "<Space><Space>", fn.dismiss_distractive)

--- Toggle spellchecker.
keymap("", "<Leader>en", ":setlocal spell! spelllang=en_us<CR>")

--- Toggle line numbering and signcolumn.
keymap("n", "<Leader>nu", fn.toggle_all_ancillary_elements)
keymap("n", "<Leader>nU", fn.toggle_numbers_signs)

--- Put a timestamp (Russian format).
keymap("n", "<Leader>ts", "i<C-R>=strftime('%d/%m/%y %H:%M:%S')<CR><Esc>")

--- Search for visually selected text.
keymap("v", "//", [[y/\V<C-R>=escape(@",'/\')<CR><CR>]])

--- Open file with the system standard utility.
keymap("n", "<Leader>x", ":!" .. open .. ' <C-R>=expand("<cfile>")<CR><CR>')

--- Save changes to a file.
keymap("n", "<C-s>", ":update<CR>")
--- Source the current buffer.
keymap("n", "<A-s>", ":so<CR>")

--- Break a line at the next space or at the char you searched with `f<char>`.
--- In visual selection, it is applied to all spanned lines.
keymap("n", "<Space>b<Space>", "f<Space>r<CR>")
keymap("n", "<Space>bb", "i<CR><Esc>")

keymap("x", "<Space>b<Space>", ":call SplitBySep()<CR>")
keymap("x", "<Space>bb", [[:call SplitBySep(getreg('/'))<CR>]])

--- Paste last yanked text in place of selected one.
keymap("v", "p", '"_dP')

--- Repeat the last colon command.
keymap("n", "<A-r>", ":@:<CR>")

--- Center cursor when moving half-page or searching (@ThePrimeagen).
keymap("n", "<C-d>", "<C-d>zz")
keymap("n", "<C-u>", "<C-u>zz")
keymap("n", "<A-n>", "nzzzv")
keymap("n", "<A-N>", "Nzzzv")

keymap("n", "[c", "[czz")
keymap("n", "]c", "]czz")

--- Open the current buffer in a new tab.
--- When it is not needed anymore, one can close it with ZZ or ZQ.
keymap("n", "<Space>t", ":tabnew %<CR>")

--- Wrap Python's <symbol> with print(f"""{<symbol>=}""")
--- 1. symbol under the cursor
--- 2. the whole line
--- 3. the visually selected text
keymap("n", "<Space>p", function()
  fn.left_right_paste('yiwO<Esc>p$a=}""")<Esc>', '^iprint(f"""{<Esc>')
end)
keymap("n", "<Space>P", function()
  fn.left_right_paste('$a=}""")<Esc>', '^iprint(f"""{<Esc>')
end)
keymap("v", "<Space>p", function()
  fn.left_right_paste('yO<Esc>p$a=}""")<Esc>', '^iprint(f"""{<Esc>')
end)

--- Start gutui in FloatingTerm instance of the 'bterm' plugin.
keymap("n", "<Leader>g", fn.gitui)

--- Toggle the diff mode for two aligned buffers.
keymap("n", "<Leader>cv", misc.cmp_buffs_toggle)

--- Trim trailing whitespaces.
api.nvim_create_user_command("Trim", fn.trim, { range = "%" })

--- Remove swap files of the file opened.
api.nvim_create_user_command(
  "Rmswp", [[silent !rm "$XDG_STATE_HOME/nvim/swap/"*'%:t'*]],
  {}
)

--- Paste cmd's output into the current buffer.
api.nvim_create_user_command(
  "Insert", -- 'In*' is easier to complete with Tab than 'Pa*'.
  fn.paste_into_buffer,
  { nargs = "+", complete = fn.complete_lua_or_vim }
)

--- Print lua table in the cmdline window.
api.nvim_create_user_command("Print", fn.print_inspect, {
  nargs = "+",
  complete = fn.complete_lua_or_vim,
})

--- Set 'nowrap' if window width is < 110 char.
local aug_tw = api.nvim_create_augroup("AutoTW", { clear = true })
api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
  callback = fn.narrow_win_nowrap,
  group = aug_tw,
})
