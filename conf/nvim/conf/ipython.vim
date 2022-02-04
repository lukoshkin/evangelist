"" This plugin has some bugs, but still usable.
"" bug1: you send a next cell, but it executes the previous one instead.
"" bug2: some mappings work in a way you don't expect (e.g. IPythonCellRestart
"" can kill Ipython session, thus, making you to reopen the app manually).

Plug 'hanschen/vim-ipython-cell', { 'for': 'python' }

let g:ipython_cell_tag = ['# %%', '#%%', '## <codecell>', '# In[']
"" Use %cpaste "magic function" that allows for error-free pasting.
"" Moreover, it sends all lines in a cell at once instead of one by one.
let g:slime_python_ipython = 1

"" The setting below work only in a tmux session when
"" Vim is open in the left pane, and Ipython in the right one.
command! Run :IPythonCellRun
command! RunTime :IPythonCellRunTime
command! Clear :IPythonCellClear

"" (*) solves bug1 in some way.
fun! SlimeSendCellJump ()
  execute "normal \<Plug>SlimeSendCell"
  IPythonCellNextCell
endfun

"" Note: the order of sourcing Slime and IPython configs does matter.
"" ####  First, import Slime's one, then those of IPython.
"" 1. Cell execution (bug 1).
"" 2. Execute and jump to the next cell (bug 1).
"" 3. Send cell with slime (*) and jump to the next one
""    (NOTE: it overrides SlimeSendCell mapping).
"" 4. Jump to the next cell.
"" 5. Jump to the previous one.
"" 6. Close all matplotlib figure windows.
"" 7. Restart the kernel (bug 2).
augroup IpyCells
  au!
  au FileType python nnoremap <CR> :IPythonCellExecuteCell<CR>
  au FileType python nnoremap <Space><CR> :IPythonCellExecuteCellJump<CR>
  au FileType python nnoremap <Leader><CR> :call SlimeSendCellJump()<CR>
  au FileType python nnoremap <Space>n :IPythonCellNextCell<CR>
  au FileType python nnoremap <Space>p :IPythonCellPrevCell<CR>
  au FileType python nnoremap <Space>x :IPythonCellClose<CR>
  au FileType python nnoremap <Space>00 :IPythonCellRestart<CR>
augroup END
