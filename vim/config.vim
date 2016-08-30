syntax on

colorscheme gruvbox

set background=dark
set number " enable line numbers
"set paste " don't realign on paste in insert mode
set smartindent
set shell=/bin/bash
set tabstop=2
set shiftwidth=2
set expandtab
set visualbell
set noerrorbells
set laststatus=2
set backspace+=start,eol,indent
set cursorline
set autochdir
set wildmenu

set nowritebackup " prevent vim from creating ultra shortliving tmp files

scriptencoding utf-8
set encoding=utf-8

" never fold
set nofoldenable
au BufRead * normal zR

" Highlight searches
set hlsearch
" Ignore case of searches
set ignorecase
" Highlight dynamically as pattern is typed
set incsearch

" undo history
set hidden " persist undo history
set undofile
set undodir=$HOME/.vimundo

set backupdir=~/.vim/backups
set directory=~/.vim/swaps

let mapleader = "\<Space>"
set clipboard=unnamed
set visualbell
set noerrorbells
set mouse=a

" Remember last cursor position
function! ResCur()
    if line("'\"") <= line("$")
        normal! g`"
        return 1
    endif
endfunction

augroup resCur
    autocmd!
    autocmd BufWinEnter * call ResCur()
augroup END

" filetypes
au BufRead,BufNewFile {Gemfile,Rakefile,Vagrantfile,Thorfile,Procfile,Guardfile,config.ru,*.rake} set ft=ruby
au BufRead,BufNewFile *.{md,markdown,mdown,mkd,mkdn,txt} set ft=mkd
au BufRead,BufNewFile *.{coffee} set ft=coffee
au BufRead,BufNewFile *.{go} set ft=go
au BufRead,BufNewFile *.{swift} set ft=swift
au BufRead,BufNewFile *.{less} set ft=less
au BufRead,BufNewFile *.{rs} set ft=rust colorcolumn=99
au BufRead,BufNewFile *.{py} set colorcolumn=79
au BufRead,BufNewFile *.{xtx} set ft=tex
au BufRead,BufNewFile *.{toml} set ft=toml
au BufRead,BufNewFile *.{fish} set ft=fish
au BufRead,BufNewFile *.{ts,tsx} set ft=typescript colorcolumn=120
au BufRead,BufNewFile Dockerfile set ft=Dockerfile
au BufRead,BufNewFile *.{js} set colorcolumn=80
au BufRead,BufNewFile *.{go} silent SyntasticToggleMode

" Display tabs and trailing spaces visually
set list listchars=tab:\ \ ,trail:·

" Toggles the background color, and reloads the colorscheme.
command! ToggleBackground call <SID>ToggleBackground()
function! <SID>ToggleBackground()
    let &background = ( &background == "dark"? "light" : "dark" )
    if exists("g:colors_name")
        exe "colorscheme " . g:colors_name
    endif
endfunction

let g:go_snippet_engine = "neosnippet"

if &term =~ '^xterm'
  " tmux knows the extended mouse mode
  set ttymouse=xterm2
endif

" TODO remove: https://github.com/neovim/neovim/issues/2294
nmap <BS> <C-W>h

if has('nvim')
  let $NVIM_TUI_ENABLE_TRUE_COLOR = 1
  let $NVIM_TUI_ENABLE_CURSOR_SHAPE = 1
endif
