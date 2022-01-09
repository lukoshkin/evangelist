Plug 'neoclide/coc.nvim', {'branch': 'release'}

let g:coc_global_extensions = [
      \ 'coc-sh',
      \ 'coc-json',
      \ 'coc-pyright',
      \ 'coc-vimlsp',
      \ 'coc-clangd' ]

"" Make linting popups readable in the colorscheme used by evangelist
hi CocErrorSign ctermfg=DarkRed
hi CocWarningSign ctermfg=Yellow
hi CocHintSign ctermfg=Blue

hi CocErrorFloat guifg=#6D0604
hi CocWarningFloat guifg=#D1CD66
hi CocHintFloat guifg=#04376D

"" Highlight a symbol and its references when holding the cursor over it.
"" A 'symbol' in computer programming is a primitive data type whose
"" instances have a unique human-readable form (taken from Wikipedia).
autocmd CursorHold * silent call CocActionAsync('highlight')

"" coc.nvim uses some unicode characters in autoload/float.vim
"" (required for Vim)
set encoding=utf-8

"" Longer 'updatetime' (default is 4000 ms) leads to
"" noticeable delays and poor user experience.
set updatetime=1000

"" Signcolumn settings
if has("nvim-0.5.0") || has("patch-8.1.1564")
  set signcolumn=number
else
  set signcolumn=auto:1-2
endif


"" Modify statusline so that the diagnostics summary appears on it
set statusline=%<%f\ %h%m%r
set statusline+=\ \ \ \ \ \ \ \ \|\|
set statusline+=\ %{coc#status()}%{get(b:,'coc_current_function','')}
set statusline+=\ %=%-14.(%l,%c%V%)\ %P


if has('nvim') && !empty($CONDA_PREFIX)
  let g:python3_host_prog = $CONDA_PREFIX . '/bin/python'
endif


"" Tab triggers the completion and can be used to navigate through options.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

"" <C-Space> triggers the completion.
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif


"" `[g` and `]g` navigate through diagnostics.
"" `:CocDiagnostics` shows the diagnostics in the location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

"" GoTo code navigation.
"" Note 'gt' is mapped to 'go to the next tab page' in Vim defaults.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

"" <S-k> to show documentation in a preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction


"" Rename symbol.
nmap <leader>rn <Plug>(coc-rename)
"" Apply CodeAction to the current buffer.
nmap <leader>aa  <Plug>(coc-codeaction)
"" Apply AutoFix to a problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

"" Manage function and class objects (better to use visual selection).
"" NOTE: Requires 'textDocument.documentSymbol' support.
"" See 'v:operator' to come up with possible solutions
"" for 'if' and 'ic' in operator pending mode.
autocmd FileType sh,bash,zsh,cpp xmap if <Plug>(coc-funcobj-i)V
autocmd FileType python xmap if <Plug>(coc-funcobj-i)Vj}k
autocmd FileType cpp xmap af <Plug>(coc-funcobj-a)Vj
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

"" Format the current buffer (e.g. for python autopep8 is required).
command! -nargs=0 Format :call CocAction('format')
"" Show the diagnostics in the location list.
command! Diagnostics :CocDiagnostics<CR>
command! ToggleDiag :silent! call CocAction('diagnosticToggle')<CR>

"" <C-f> and <C-b> for scrolling float windows/popups.
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f>
        \ coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b>
        \ coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"

  inoremap <silent><nowait><expr> <C-f>
        \ coc#float#has_scroll() ?
        \ "\<c-r>=coc#float#scroll(1)\<CR>" : "\<Right>"
  inoremap <silent><nowait><expr> <C-b>
        \ coc#float#has_scroll() ?
        \ "\<c-r>=coc#float#scroll(0)\<CR>" : "\<Left>"

  vnoremap <silent><nowait><expr> <C-f>
        \ coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <C-b>
        \ coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif
