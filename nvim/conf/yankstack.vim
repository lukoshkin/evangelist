let g:yankstack_yank_keys = ['y', 'd']

execute "set <A-p>=\ep"
execute "set <A-P>=\eP"
nmap <A-p> <plug>(yankstack_substitute_older_paste)
nmap <A-P> <plug>(yankstack_substitute_newer_paste)
