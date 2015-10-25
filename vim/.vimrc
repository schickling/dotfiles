set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

exe 'source' '~/.config/vim/plugins.vim'
exe 'source' '~/.config/vim/config.vim'
exe 'source' '~/.config/vim/mappings.vim'

for f in split(globpath('~/.config/vim', 'plugin.*.vim'), '\n')
  exe 'source' f
endfor

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

colorscheme solarized
exe 'source' '~/.config/vim/theme.vim'
