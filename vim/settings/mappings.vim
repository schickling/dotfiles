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
nmap <Space> i

map \|\| :so $HOME/.vimrc<CR>:e<CR>

" Window switching
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
imap <C-J> <C-O><C-J>
imap <C-K> <C-O><C-K>
imap <C-L> <C-O><C-L>
imap <C-H> <C-O><C-H>
imap <C-w> <C-o><C-w>

" Buffers
noremap <leader>. :bn<CR>
noremap <leader>m :bp<CR>
noremap <leader>n :bp<bar>bd #<CR>
noremap <leader>b :BufOnly<CR>
noremap <leader><leader> :e #<CR>

" quick close
map Q :wqa<CR>

" clear search highlight
noremap <leader>/ :nohl<CR>

" toggle color schema
noremap <leader>\ :ToggleBackground<CR>

" vpaste
map vp :exec "w !vpaste ft=".&ft<CR>
vmap vp <ESC>:exec "'<,'>w !vpaste ft=".&ft<CR>
