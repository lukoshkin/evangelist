"" Note that setting the 'cursorline' or 'cursorcolumn' options
"" can cause Vim to respond slowly, especially for large files
"" or files with long lines.
"" See:
"" - https://vim.fandom.com/wiki/Highlight_current_line
"" - https://vim.fandom.com/wiki/Faster_loading_of_large_files
set cursorline
set colorcolumn=80

"" Title in terminal window bar; confirm before quitting
"" if there are unsaved changes.
set title
set confirm
set number relativenumber

"" NOTE: if dealing with Neovim, v:version is always 800.
if v:version >= 800
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

"" Incremental hl-search when replacing.
"" (for old Neovim versions)
if has('nvim')
  set inccommand=nosplit
endif

"" Enable 'enhanced mode' of Vim cmd-line completion.
"" By default, wildmenu is on in Neovim and off in Vim.
set wildmenu
set wildmode=longest:full,full
"" longest:full,full stands for completing till the longest common string,
"" on the first tab, also starting the 'wildmenu', and then completing next
"" full match on subsequent tab presses.

"" Buffer updates instead of updating all the time.
set lazyredraw

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

"" '//' at the end makes vim use abs. file path,
"" thus, avoiding name collisions.
set directory=$XDG_DATA_HOME/nvim/swap//
