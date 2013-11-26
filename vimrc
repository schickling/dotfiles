set nocompatible
filetype off

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" ################
" # Settings #####
" ################

Bundle 'gmarik/vundle'
Bundle 'altercation/vim-colors-solarized'
Bundle 'kchmck/vim-coffee-script'
Bundle 'scrooloose/nerdtree'
Bundle 'scrooloose/syntastic'
Bundle 'kien/ctrlp.vim'
Bundle 'bling/vim-airline'
Bundle 'tpope/vim-fugitive'
Bundle 'scrooloose/nerdcommenter'
Bundle 'elzr/vim-json'
Bundle 'Raimondi/delimitMate'

filetype plugin indent on
syntax enable
colorscheme solarized

" ################
" # Settings #####
" ################

set expandtab
set smarttab                " Use tabs for indentation and spaces for alignment
set number
set tabstop=4               " a tab is four spaces
set shiftwidth=4            " number of spaces to use for autoindenting
set softtabstop=4           " when hitting <BS>, pretend like a tab is removed, even if spaces
set visualbell              " don't beep
set noerrorbells            " don't beep
set exrc                    " enable per-directory .vimrc files
set secure                  " disable unsafe commands in local .vimrc files
set mouse=a
set laststatus=2            " Always show the status line

" Airline
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1

" ################
" # Shortcuts ####
" ################

" With a map leader it's possible to do extra key combinations
let mapleader = ","
let g:mapleader = ","

" easier window navigation
nmap <C-h> <C-w>h
nmap <C-j> <C-w>j
nmap <C-k> <C-w>k
nmap <C-l> <C-w>l

" Fast saves
nmap <leader>w :w!<cr>

imap jj <Esc>            " Easy escaping to normal model

" Open splits
nmap vs :vsplit<cr>
nmap sp :split<cr>

" Resize vsplit
nmap <C-v> :vertical resize +5<cr>
nmap 25 :vertical resize 40<cr>
nmap 50 <c-w>=
nmap 75 :vertical resize 120<cr>

nmap <C-b> :NERDTreeToggle<cr>
