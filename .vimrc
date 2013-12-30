set nocompatible
filetype off
set encoding=utf-8

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

if filereadable(expand("~/.vimrc.bundles"))
	source ~/.vimrc.bundles
endif

if filereadable(expand("~/.vimrc.config"))
	source ~/.vimrc.config
endif
