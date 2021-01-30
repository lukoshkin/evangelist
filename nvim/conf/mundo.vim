if has('python3')
  nnoremap <leader>u :MundoToggle<CR>
else
  " written in pure Vimscript
  nnoremap <leader>u :UndotreeToggle<CR>
endif

" Undo history is persistent across different vim sessions.
set undofile
set undodir=$XDG_DATA_HOME/nvim/site/undo | call mkdir(&undodir,   'p')
" NOTE: One can also set up auto removal of
"       old undo files with cron or anacron
