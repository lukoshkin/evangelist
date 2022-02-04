Plug 'othree/eregex.vim'

"" By default, the functionality is disabled.
"" When enabled, case sensitive search is used.
"" '1M/pattern/i' makes the pattern case insensitive.
let g:eregex_default_enable = 0
let g:eregex_force_case = 1

nnoremap <leader>re :call eregex#toggle()<CR>
"" :S - for substitution
"" :G - for global
"" :V - for vglobal
