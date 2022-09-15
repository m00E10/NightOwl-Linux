" Have vim colors be different from terminal defaults
hi Normal ctermfg=7 ctermbg=0

" Bottom right col/row numbers
set ruler

" Enable line numbers, toggle with ctrl+n
set number

" Ctrl+n in normal mode toggles line numbers
:nmap <C-N> :set invnumber<CR>

" set paste mode toggle with F2
set pastetoggle=<F2>

" Enable syntax highlighting
syntax enable
syntax on
filetype plugin indent on

" Make tabs a series of spaces
set expandtab
" Make tabs 2 spaces long
set tabstop=2
set softtabstop=2
set shiftwidth=2

" On return, keep indent of previous line
set autoindent

" Themeing for line numbers
"highlight LineNr term=bold cterm=NONE ctermfg=LightGrey ctermbg=NONE gui=NONE guifg=DarkGrey guibg=NONE
highlight LineNr term=bold cterm=NONE ctermfg=Yellow ctermbg=NONE gui=NONE guifg=DarkGrey guibg=NONE
" Enable cursor line
set cursorline
" Only highlight the line NUMBER, dont underline the whole line
set cursorlineopt=number
" Themeing for current line number
highlight CursorLineNr cterm=bold term=bold gui=bold ctermfg=1
