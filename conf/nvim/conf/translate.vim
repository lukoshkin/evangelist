Plug 'voldikss/vim-translator'

let g:translator_source_lang = 'ru'
let g:translator_target_lang = 'en'

"" Replace russian word with the english translation.
nmap <silent> <Leader>tr <Plug>TranslateR
vmap <silent> <Leader>tr <Plug>TranslateRV
