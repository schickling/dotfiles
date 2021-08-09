call plug#begin('~/.vim/plugged')

" Layout
Plug 'morhetz/gruvbox'
Plug 'edkolev/tmuxline.vim'
Plug 'itchyny/lightline.vim'


" Tools
Plug 'scrooloose/nerdcommenter'
Plug 'tpope/vim-fugitive'
Plug 'scrooloose/nerdtree'
Plug 'kien/ctrlp.vim'
Plug 'scrooloose/syntastic'
Plug 'Shougo/neosnippet'
Plug 'Shougo/neosnippet-snippets'
Plug 'Raimondi/delimitMate'
Plug 'kris89/vim-multiple-cursors'
Plug 'schickling/vim-bufonly'
Plug 'tpope/vim-surround'
Plug 'ervandew/supertab'
Plug 'majutsushi/tagbar'
Plug 'nelstrom/vim-qargs'
Plug 'christoomey/vim-tmux-navigator'
Plug 'godlygeek/tabular'
Plug 'bling/vim-bufferline'
Plug 'tpope/vim-abolish' " Case convertion
Plug 'tpope/vim-repeat' " Repeat plugin commands using `.`
Plug 'zimbatm/direnv.vim'
Plug 'terryma/vim-expand-region'
"Plug 'Shougo/deoplete.nvim'
Plug 'Valloric/YouCompleteMe', { 'do': './install.py' }
"Plug 'ternjs/tern_for_vim', { 'do': 'npm install', 'for': 'javascript' }
Plug 'Quramy/tsuquyomi', { 'for': 'javascript' }
Plug 'Shougo/vimproc.vim', { 'do': 'make -f make_mac.mak' }

" Languages
Plug 'othree/html5.vim'
"Plug 'wting/rust.vim'
Plug 'plasticboy/vim-markdown'
"Plug 'kchmck/vim-coffee-script'
Plug 'ekalinin/Dockerfile.vim'
Plug 'maksimr/vim-jsbeautify'
"Plug 'dag/vim2hs'
"Plug 'groenewege/vim-less'
"Plug 'cespare/vim-toml'
Plug 'fatih/vim-go'
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
Plug 'othree/yajs.vim', { 'for': 'javascript' }
Plug 'mxw/vim-jsx', { 'for': 'javascript' }
Plug 'nvie/vim-flake8'
Plug 'dag/vim-fish'
"Plug 'keith/swift.vim'
Plug 'leafgarland/typescript-vim'
Plug 'jparise/vim-graphql'

call plug#end()
