function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()

  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end

local open
local system = os.capture('uname')

if system == 'Linux' then
  open = 'xdg-open'
elseif system == 'Darwin' then
  open = 'open'
else
  --- presumably on Windows.
  --- 'start some.exe' - do we go like this?
  open = 'start'
end


local keymap = vim.keymap.set
vim.g.maplocalleader = '<Space>'

local aug0 = vim.api.nvim_create_augroup('EasierJJ', {clear = true})
vim.api.nvim_create_autocmd('InsertEnter', {
  command = 'set timeoutlen=200',
  group = aug0
})

vim.api.nvim_create_autocmd('InsertLeave', {
  command = 'set timeoutlen=1000',
  group = aug0
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

--- Turn off highlighting and dismiss messages below the status bar.
keymap('n', '<Space><Space>', ':nohlsearch<Bar>echo<CR>')

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
keymap('', 'gf', ':edit <cfile><CR>')

--- Open file with the system standard utility.
keymap('n', '<leader>x', ':!'..open..' <C-R>=expand("<cfile>")<CR><CR>')

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

  fun! BottomtermToggle()
    if exists('t:bottom_term') && bufnr(t:bottom_term) >= 0
      let l:winid = bufwinid(t:bottom_term)
      if l:winid < 0
        execute 'sb' t:bottom_term
      else
        call win_gotoid(l:winid)
        return
      endif
    else
      new
      setlocal buftype=nofile bufhidden=hide noswapfile
      terminal
      let t:bottom_term = bufname()
    endif

    resize 8
    startinsert
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

--- Bottom terminal for a current window.
local aug1 = vim.api.nvim_create_augroup('TermInsert', {clear=true})
vim.api.nvim_create_autocmd('BufEnter', {
  pattern = 'term://*',
  command = 'norm i<CR>',
  group = aug1,
})

keymap('n', '<S-A-t>', vim.fn.BottomtermToggle)
keymap('t', '<Esc>', '<C-\\><C-n>')
keymap('t', '<S-A-t>', '<Esc>:q<Bar>echo<CR>', {remap=true})
keymap('t', '<C-w>', '<Esc><C-w>', {remap=true})
keymap('t', '<C-t>', '<C-w>Li', {remap=true})

--- Paste previously yanked text in place of selected one.
keymap('v', 'p', '"_dP')
