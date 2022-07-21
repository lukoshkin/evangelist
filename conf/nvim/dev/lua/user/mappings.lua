local keymap = require'lib.utils'.keymap
local open = require'lib.utils'._opener
vim.g.maplocalleader = '<Space>'

local aug_jj = vim.api.nvim_create_augroup('EasierJJ', {clear = true})
vim.api.nvim_create_autocmd('InsertEnter', {
  command = 'set timeoutlen=200',
  group = aug_jj
})

vim.api.nvim_create_autocmd('InsertLeave', {
  command = 'set timeoutlen=1000',
  group = aug_jj
})

keymap('i', 'jj', '<Esc>')

keymap('n', '<A-j>', 'o<Esc>')
keymap('n', '<A-k>', '<S-o><Esc>')
keymap('n', '<A-h>', 'i<Space><Esc>')
keymap('n', '<A-l>', 'a<Space><Esc>')

keymap('n', '<S-A-j>', 'o<Esc>k')
keymap('n', '<S-A-k>', '<S-o><Esc>j')
keymap('n', '<S-A-h>', 'i<Space><Esc>l')
keymap('n', '<S-A-l>', 'a<Space><Esc>h')

local function toggle_mouse()
  --- https://unix.stackexchange.com/questions/156707
  if vim.o.mouse == 'a' then
    vim.o.mouse = ''
  else
    vim.o.mouse = 'a'
  end
end

keymap({'n', 'i'}, '<A-m>', toggle_mouse)

keymap('n', '<C-j>', ':m+1<CR>==')
keymap('n', '<C-k>', ':m-2<CR>==')
keymap('v', '<C-j>', ":m'>+<CR>gv=gv")
keymap('v', '<C-k>', ':m-2<CR>gv=gv')

--- Copy to clipboard selected text or the whole file.
keymap('x', '<leader>y', '"+y')
keymap('n', '<leader>y', ':%y+<CR>')

--- Change the terminal bg's transparency from within Vim
--- (valid only for Linux systems; maybe, just Ubuntu).
keymap('', '<A-+>', ':silent !transset -a --inc .02<CR>')
keymap('', '<A-->', ':silent !transset -a --dec .02<CR>')


local function discard_distractive ()
  require'notify'.dismiss()
  vim.cmd ':nohlsearch | echo'
end

--- Turn off highlighting and dismiss messages below the status bar.
keymap('n', '<Space><Space>', discard_distractive)


--- Toggle spellchecker.
keymap('', '<leader>en', ':setlocal spell! spelllang=en_us<CR>')

--- Toggle line numbering and CoC-diagnostics
--- (if installed, otherwise, it is ignored).
keymap('n', '<leader>nu', ':set invnu invrnu<CR>')

--- Put a timestamp (Russian format).
keymap('n', '<leader>ts', "i<C-R>=strftime('%d/%m/%y %H:%M:%S')<CR><Esc>")

--- Search for visually selected text.
keymap('v', '//', [[y/\V<C-R>=escape(@",'/\')<CR><CR>]])

--- Go to file (but first, create if doesn't exist).
--- Won't work on python imports and cpp includes after remapping.
--- One can use 'gd' instead.
keymap('', 'gf', ':edit <cfile><CR>')

--- Open file with the system standard utility.
keymap('n', '<leader>x', ':!'.. open ..' <C-R>=expand("<cfile>")<CR><CR>')

--- Save changes to a file.
keymap('n', '<C-s>', ':w<CR>')

--- Break a line at the next space or at the char you searched with `f<char>`.
--- In visual selection, it is applied to all spanned lines.
keymap('n', '<Space>b<Space>', 'f<Space>r<CR>')
keymap('n', '<Space>b', ';li<CR><Esc>')

vim.cmd[[
  fun! SplitBySep (...)
    "" '...' is like '*args' in Python.

    "" Note: the content of register l will be lost after the function call.
    "" Key 'l' is chosen as "the least convenient" for register use.

    "" I believe there is no need to check the num of args.
    " if a:0 > 1
    "   echoerr 'More than one argument passed'
    "   return
    " endif

    let l:sep = get(a:, 1, ' ')

    mark l
    execute 'normal 0"ly/'.l:sep.'<CR>'
    silent! execute 's;\('.l:sep.'\)\(\S\)\@=;\1\r;g'
    mark L

    " let l:len = strlen(getreg('l'))
    " let l:indent = repeat(' ', l:len)

    " 'l+1,'Ls;^;\=l:indent;

    normal 'lj
    normal ='L
    silent 'l,'LTrim

    delmarks lL
    let @l=''
  endfun
]]

keymap('x', '<Space>b<Space>', ':call SplitBySep()<CR>')
keymap('x', '<Space>bb', [[:call SplitBySep(getreg('/'))<CR>]])

--- Trim trailing whitespaces.
--- TODO: rewrite it so the cursor position doesn't change.
vim.api.nvim_create_user_command(
  'Trim',
  [[<line1>,<line2>s/\s\+$//e | nohlsearch]],
  { range = '%' }
)

--- Remove swap files of the file opened.
vim.api.nvim_create_user_command(
  'Rmswp',
  [[silent !rm "$XDG_DATA_HOME/nvim/swap/"*'%:t'*]],
  {}
)

--- Paste previously yanked text in place of selected one.
keymap('v', 'p', '"_dP')
