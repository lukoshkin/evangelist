nnoremap <leader>u :MundoToggle<CR>

" Undo history is persistent across different vim sessions.
set undofile
set undodir=$XDG_DATA_HOME/nvim/site/undo
" NOTE: One can also set up auto removal of
"       old undo files with cron or anacron
