"" Easier exit from Insert mode
inoremap jj <Esc>
"" 'autocmd' helps you make commands executed on some event.
"" The two lines below mean: set timeout for all keystroke sequences
"" to 200ms when entering 'insert' mode and 1000ms when leaving it.
"" This applies to any file type as the asterisks below specify.
augroup EasierJJ
  "" The next line removes autocmds
  "" defined in the context of autogroup
  autocmd!
  autocmd InsertEnter * set timeoutlen=200
  autocmd InsertLeave * set timeoutlen=1000
augroup END
"" Autogroup prevents pile-up caused by several copies of the same autocmd
"" when sourcing a file/plugin several times. The same effect but
"" without autogroup could be achieved by using the trailing '!'
"" (i.e., 'autocmd! ...') in the definition of autocmds. However,
"" with autogroup, you also get namespacing, order and flexibility.


"" Add empty an empty line or space in the direction
"" which a movement key specifies. Instead of 'A' letter one can use 'M'
"" for mappings, which stands for Meta and is equivalent to Alt
"" on Dell laptops.
if !has('nvim')
  execute "set <A-j>=\ej"
  execute "set <A-k>=\ek"
  execute "set <A-h>=\eh"
  execute "set <A-l>=\el"

  execute "set <S-A-j>=\eJ"
  execute "set <S-A-k>=\eK"
  execute "set <S-A-h>=\eH"
  execute "set <S-A-l>=\eL"
endif

nnoremap <A-j> o<Esc>
nnoremap <A-k> <S-o><Esc>
nnoremap <A-h> i<Space><Esc>
nnoremap <A-l> a<Space><Esc>

nnoremap <S-A-j> o<Esc>k
nnoremap <S-A-k> <S-o><Esc>j
nnoremap <S-A-h> i<Space><Esc>l
nnoremap <S-A-l> a<Space><Esc>h


"" Mouse support
if !has('nvim')
  execute "set <A-m>=\em"
endif

noremap <A-m> :call ToggleMouse()<CR>
inoremap <A-m> <Esc>:call ToggleMouse()<CR>a

"" https://unix.stackexchange.com/questions/156707
function! ToggleMouse()
    " check if mouse is enabled
    if &mouse == 'a'
        " disable mouse
        set mouse=
    else
        " enable mouse everywhere
        set mouse=a
    endif
endfunc


"" Copy to clipboard (the whole buffer or selected lines)
xnoremap <leader>y "+y
nnoremap <leader>y :%y+<CR>

"" Spell checker ('<leader>e' to switch on)
"" To add ru lang, you need to download the dictionary
"" After the launch, 'z=' (nmode) over a misspelled word shows
"" the substitutions; ']s'/'[s' (nmode) - to navigate through
"" the misspelled words
map <leader>en :setlocal spell! spelllang=en_us<CR>

"" Make a timestamp ("Russian" format)
nmap <leader>ts i<C-R>=strftime('%d/%m/%y %H:%M:%S')<CR><Esc>

"" Press Space two times to turn off highlighting
"" and clear any message already displayed.
nnoremap <silent><Space><Space> :nohlsearch <Bar> echo<CR>

"" Change the bg's transparency with terminal/tmux mappings <Alt-+> and <Alt-->
noremap <silent><A-+> :silent !transset -a --inc .02<CR>
noremap <silent><A--> :silent !transset -a --dec .02<CR>
"" :silent discards the output of a command that follows it.

"" Remove all extra spaces at the end of lines
"" TODO: rewrite it so the cursor position doesn't change.
command! -range=% Trim <line1>,<line2>s/\s\+$//e | nohlsearch
"" By default, the application range is the whole file (%).
"" The exclamation mark says to replace the command if it already exists.
"" So no error will pop up when sourcing this file several times.

" Search for visually selected text
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>

"" Toggle line numbering
nnoremap <silent><leader>nu :set invnu invrnu <Bar> silent! ToggleDiag<CR>

"" Break a line at the next space or at the char you searched with `f<char>`.
"" In visual selection, it is applied to all spanned lines.
nnoremap <Space>b<Space> f<Space>r<CR>
nnoremap <Space>bb ;li<CR><Esc>

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
  normal 0"lyw
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

"" The last one splits by the '/'-register's content, i.e.,
"" the last searched pattern.
xnoremap <Space>b<Space> :call SplitBySep()<CR>
xnoremap <Space>bb :call SplitBySep(getreg('/'))<CR>

"" Note, here we use concatenation as is usual in shell.
command! Rmswp :silent !rm "$XDG_DATA_HOME/nvim/swap/"*'%:t'*

"" Open the file under the cursor.
nnoremap <leader>x :!xdg-open <C-R>=expand("<cfile>")<CR><CR>

"" Save changes to a file.
map <C-s> :w<CR>

"" Bottom terminal for a current window.
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

augroup TermInsert
  "" Start insert mode when switching to term buffer.
  autocmd!
  autocmd BufEnter term://* norm i<CR>
augroup END

"" Note: The terminal mappings below are necessary only for Neovim.
nnoremap <S-A-t> :call BottomtermToggle()<CR>
tnoremap <Esc> <C-\><C-n>
tmap <silent><S-A-t> <Esc>:q<Bar>echo<CR>
tmap <C-w> <Esc><C-w>
tmap <C-t> <C-w>Li

"" List available buffers and choose one to switch to.
noremap <leader>b :buffers<CR>:buffer<Space>

"" Paste previously yanked text in place of selected one.
vnoremap p "_dP
