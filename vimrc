set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

for f in split(globpath('$DOTFILES/vim', '*.vim'), '\n')
  exe 'source' f
endfor

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
