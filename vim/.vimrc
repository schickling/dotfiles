exe 'source' '~/.config/vim/plugins.vim'
exe 'source' '~/.config/vim/config.vim'
exe 'source' '~/.config/vim/mappings.vim'

for file in split(globpath('~/.config/vim', 'plugin.*.vim'), '\n')
  exe 'source' file
endfor
