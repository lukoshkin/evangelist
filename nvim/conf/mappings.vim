let mapleader=","
inoremap jj <Esc>
" 'autocmd' helps you make commands executed on some event.
" The two lines below mean: set timeout for all keystroke sequences
" to 200ms when entering 'insert' mode and 1000ms when leaving it.
" This applies to any file type as the asterisks below specify.
augroup JJExit
  " The next line removes autocmds
  " defined in the context of autogroup
  autocmd!
  autocmd InsertEnter * set timeoutlen=200
  autocmd InsertLeave * set timeoutlen=1000
augroup END
" Autogroup prevents pile-up caused by several copies of the same autocmd
" when sourcing a file/plugin several times. The same effect but
" without autogroup could be achieved by using the trailing '!'
" (i.e., 'autocmd! ...') in the definition of autocmds. However,
" with autogroup, you also get namespacing, order and flexibility.


" Add line below and above with <Alt-m> <Alt-Shift-m>, respectively.
" Instead of 'A' letter one can use 'M' for mappings, which stands for Meta
" and is equivalent to Alt on Dell laptops.
if !has('nvim')
  execute "set <A-m>=\em"
  execute "set <A-M>=\eM"
endif

nnoremap <A-m> o<Esc>
nnoremap <A-M> <S-o><Esc>


" Run the currently edited file (or selected lines) with python.
augroup PyExecutor
  autocmd!
  autocmd FileType python
        \ xnoremap <buffer><silent><leader>py
        \ :call PySelect() <bar> call PyExec()<CR>
  autocmd FileType python
        \ nnoremap <buffer><silent><leader>py :w !python<CR>
augroup END
" <silent> prevents the command defined on the RHS of a mapping to be printed.
" With <buffer>, one cannot call python in tmp buffers like Mundo or NERDtree.

" Note: the functions below exploit 'z' register (see :help registers).
" If you stored anything there, all the data will be lost.
" You can change the named buffer used in the command to another
" (all the hardcoded occurrences).
function! PySelect()
  call setreg('z', [])
  silent g/^import [^\.\-\n]\+/yank Z
  silent g/^from [^\.\-\n]\+/yank Z
  silent normal gv"Zy
endfunction
" 'normal' in VimScript allows you execute keystrokes.
" 'gv' tells Vim to select the same area as the one selected on
" the function call. Copied text is appended

function! PyExec()
  echo execute(join(['!python -c', shellescape(@z, 1)]))
  call setreg('z', [])
endfunction
" 'execute()' captures an output of a python-program,
" and 'echo' separates the output and the python call.


" Copy to clipboard (the whole buffer or selected lines)
xnoremap <leader>y "+y
nnoremap <leader>y :%y+<CR>


" Spell checker ('<leader>e' to switch on)
" To add ru lang, you need to download the dictionary
" After the launch, 'z=' (nmode) over a misspelled word shows
" the substitutions; ']s'/'[s' (nmode) - to navigate through
" the misspelled words
map <leader>en :setlocal spell! spelllang=en_us<CR>


"Make a timestamp ("Russian" format)
nmap <leader>t i<C-R>=strftime('%d/%m/%y %H:%M:%S')<CR><Esc>


" Press Space two times to turn off highlighting
" and clear any message already displayed.
nnoremap <silent><Space><Space> :nohlsearch<Bar>:echo<CR>


" Change the bg's transparency with terminal/tmux mappings <Alt-+> and <Alt-->
noremap <silent><A-+> :silent !transset -a --inc .02<CR>
noremap <silent><A--> :silent !transset -a --dec .02<CR>
" :silent discards the output of a command that follows it.


" Remove all extra spaces at the end of lines
command! Trim %s/\s*$//g

" Search for visually selected text
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>
