syntax on
set background=dark
set number
"set paste " don't realign on paste in insert mode
set smartindent
set tabstop=2
set shiftwidth=2
set expandtab
set visualbell
set noerrorbells
set laststatus=2
"set backspace+=start,eol,indent
set cursorline
set autochdir
"set shell=/bin/bash " Fix path"
set wildmenu

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

let mapleader = ","
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
au BufRead,BufNewFile *.{md,markdown,mdown,mkd,mkdn,txt} setf markdown
au BufRead,BufNewFile *.{coffee} set ft=coffee
au BufRead,BufNewFile *.{go} set ft=go
au BufRead,BufNewFile *.{xtx} set ft=tex
au BufRead,BufNewFile Dockerfile set ft=Dockerfile
au BufRead,BufNewFile *.{js} set colorcolumn=80

au BufWritePre *.{js} :call JsBeautify()
"au BufWritePre *.{html} :call HtmlBeautify()

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

if &term =~ '^screen'
endif

let g:neocomplete#enable_at_startup = 1
let g:go_snippet_engine = "neosnippet"

if &term =~ '^xterm'
  " thin cursor in insert mode
  let &t_SI .= "\<Esc>[6 q"
  let &t_EI .= "\<Esc>[2 q"
  " tmux knows the extended mouse mode
  set ttymouse=xterm2
endif

