Plug 'hanschen/vim-ipython-cell', { 'for': 'python' }

let g:ipython_cell_tag = ['# %%', '#%%', '## <codecell>']

"" The setting below work only in a tmux session when
"" Vim is open in the left pane, and Ipython in the right one.
command! Run :IPythonCellRun
command! RunTime :IPythonCellRunTime
command! Clear :IPythonCellClear

"" Note: the order of sourcing Slime and IPython configs does matter.
"" ####  First, import Slime's one, then those of IPython.
"" 1. Cell execution (first one overrides SlimeSendCell).
"" 2. Execute and jump to the next one.
"" 3. Close all matplotlib figure windows.
"" 4. Restart the kernel.
augroup IpyCells
  au!
  au FileType python nnoremap <CR> :IPythonCellExecuteCell<CR>
  au FileType python nnoremap <Space><CR> :IPythonCellExecuteCellJump<CR>
  au FileType python nnoremap <localleader>x :IPythonCellClose<CR>
  au FileType python nnoremap <localleader>00 :IPythonCellRestart<CR>
augroup END
