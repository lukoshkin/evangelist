set runtimepath^=$XDG_CONFIG_HOME/nvim/plugged/ctrlp.vim

" Set no max file limit
"let g:ctrlp_max_files = 0

let g:ctrlp_working_path_mode = 'ra'
" 'r' - the nearest ancestor that contains one of these directories or
" files: .git .hg .svn .bzr _darcs, and your own root markers defined
" with the g:ctrlp_root_markers option.
" 'c' - the directory of the current file
" 'a' - like 'c', but only applies when the current working directory
" outside of CtrlP isn't a direct ancestor of the directory of the
" current file
" 0 or '' (empty string) - disable this feature

" *** ignore rc block1 ***
" Set this to 1 if you want CtrlP to scan for dotfiles and dotdirs:
let g:ctrlp_show_hidden = 0

" Set MRU file mode to default
" (one can consider CtrlPMixed. It is > MRU, but quite slow)
let g:ctrlp_cmd = 'CtrlPMRU'

set wildignore+=*/tmp/*,*.swp,*.zip,*/.cache
set wildignore+=*/miniconda3,*/Music,*/Video
let g:ctrlp_custom_ignore = {
	\ 'dir':  '\v/\.(git|hg|ipynb_checkpoints)$',
	\ 'file': '\v\.(o|so|dll|ipynb|pdf)$',
	\ 'link': 'SOME_BAD_SYMBOLIC_LINKS',
	\ }
" *** ignore rc block1 ***

" NOTE: block1 does not apply when block2 is being used
" block2 works faster, so is more preferable

" *** ignore rc block2 ***
" Specify an external tool to use for listing files instead of using Vim's
" globpath(). Use %s in place of the target directory
let g:ctrlp_user_command = {
  \ 'types': {
    \ 1: ['.git', 'cd %s && git ls-files --exclude-standard'],
    \ 2: ['.hg', 'hg --cwd %s locate -I .'],
    \ },
  \ 'fallback': 'find %s -type f -readable 2> /dev/null |
    \ grep -vE "\/(\.|__)\w*" |
    \ grep -vE "(miniconda3|Music|Video|*\.(o|pdf|zip|gz|ipynb|JPG))"'
  \ }
" *** ignore rc block2 ***
