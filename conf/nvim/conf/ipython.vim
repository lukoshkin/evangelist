" The setting below work only in a tmux session when
" Vim is open in the left pane, and Ipython in the right one.
command! Run :IPythonCellRun
command! RunTime :IPythonCellRunTime
command! Clear :IPythonCellClear

# Cell execution
nnoremap <CR> :IPythonCellExecuteCell<CR>
nnoremap <C-n> :IPythonCellExecuteCellJump<CR>

" Close all matplotlib figure windows
nnoremap <localleader>x :IPythonCellClose<CR>
" Restart the kernel
nnoremap <localleader>00 :IPythonCellRestart<CR>

