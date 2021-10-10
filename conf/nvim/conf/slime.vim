let g:slime_target = "tmux"
let g:slime_paste_file = "/tmp/.slime_paste"
let g:slime_dont_ask_default = 1
let g:slime_default_config = {
      \ "socket_name": "default",
      \ "target_pane": "{top-right}" }

" To send just a line, use <C-c><C-c> (default mapping).
" Send text delimited by #%% (emulation of cells) with <C-s>.
let g:slime_cell_delimiter = "#%%"
nmap <leader>s <Plug>SlimeSendCell

