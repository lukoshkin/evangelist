let g:yoinkMaxItems = 10  " default: 10
let g:yoinkIncludeDeleteOperations = 0  " default: 0

if has('nvim')
  let g:yoinkSavePersistently = 1
else
  let g:yoinkSavePersistently = 0
endif

nmap <M-n> <plug>(YoinkPostPasteSwapBack)
nmap <M-p> <plug>(YoinkPostPasteSwapForward)

nmap p <plug>(YoinkPaste_p)
nmap P <plug>(YoinkPaste_P)

noremap <Space>yb <plug>(YoinkRotateBack)
noremap <Space>yf <plug>(YoinkRotateForward)

" 1. To _C_lear _Y_anks
" 2. To list (_S_how) _Y_anks
"    (Note: the last yank is always kept)
noremap <Space>sy :Yanks<CR>
noremap <Space>cy :ClearYanks<CR>
