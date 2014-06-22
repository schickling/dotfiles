" splits
nnoremap <silent> vv <C-w>v
nnoremap <silent> ss <C-w>s

" format the entire file
nnoremap <leader>fef :normal! gg=G``<CR>
nnoremap <silent> <leader>x :call JsBeautify()<cr>

nnoremap <silent> <leader>tt :TagbarToggle<CR>

" Wrapped lines goes down/up to next row, rather than next line in file.
noremap j gj
noremap k gk
inoremap kj <Esc>l
nmap <Space> i

map \|\| :so $MYVIMRC<CR>

" Window
map <C-J> <C-W>j<C-W>_
map <C-K> <C-W>k<C-W>_
map <C-L> <C-W>l<C-W>_
map <C-H> <C-W>h<C-W>_

" Buffers
noremap <leader>. :bn<CR>
noremap <leader>m :bp<CR>
noremap <leader>n :bp<bar>bd #<CR>
noremap <leader>b :BufOnly<CR>

" quick close
map Q :wqa<CR>
