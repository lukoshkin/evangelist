"" Note that setting the 'cursorline' or 'cursorcolumn' options
"" can cause Vim to respond slowly, especially for large files
"" or files with long lines.
"" See:
"" - https://vim.fandom.com/wiki/Highlight_current_line
"" - https://vim.fandom.com/wiki/Faster_loading_of_large_files
set cursorline
set colorcolumn=80
set number relativenumber

if has('nvim') || has('patch-8.0')
  set termguicolors
endif

"" Default indentation
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
set smartindent

"" Pattern searching (highlighting and search before <Enter> hit)
set hlsearch
set incsearch

"" Incremental hl-search when replacing (for Neovim)
if has('nvim')
  set inccommand=nosplit
endif

"" Provide tab-completion for all file-related tasks.
set path+=**

"" Display all matching files when tab complete.
set wildmenu

"" Buffer updates instead of updating all the time.
set lazyredraw

"" Switch to another buffer even if the current one is modified.
"" (Can lead to closing of hidden buffers without saving if using
""  such exit options like `<prefix>-Q` in Tmux. Likely, a swap file
""  will be created in this case, so no data will be lost.)
" set hidden

"" ru2en mapping in all modes but insert.
"" Change the symbols inserted (ru or en) with <C-^>.
"" A good alternative would be 'lyokha/vim-xkbswitch' plugin.
set keymap=russian-jcukenwin
"" start from 'en'
set iminsert=0
set imsearch=0

"" Set case-insensitive search and command modes as default.
set ignorecase
set smartcase
"" 'smartcase' option switches from insensitive to sensitive search mode
"" whenever there is a capital letter in a pattern. One can use '\C' or \c'
"" escape sequences anywhere in the pattern to make the search case-sensitive
"" or -insensitive, respectively, regardless of these two options.

"" Don't insert two spaces after a '.', '?' and '!' with a join command.
set nojoinspaces

"" Split appears on the right or below correspondingly instead of
"" taking the the place of the current buffer.
set splitbelow
set splitright

"" Start scrolling before reaching the screen borders.
" set scrolloff=8
" set sidescrolloff=8

"" '//' at the end makes vim use abs. file path,
"" thus, avoiding name collisions.
set directory=$XDG_DATA_HOME/nvim/swap//
