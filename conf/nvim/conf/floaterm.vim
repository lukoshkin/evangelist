Plug 'voldikss/vim-floaterm'

nnoremap <A-t> :FloatermToggle scratch<CR>
tnoremap <A-t> <C-\><C-n>:FloatermToggle scratch<CR>

let g:floaterm_opener = 'vsplit'
" let g:floaterm_width = 0.8
" let g:floaterm_height = 0.8
" let g:floaterm_wintitle = 0

hi Floaterm guibg=#343746
hi FloatermBorder guifg=#343746 guibg=#343746
