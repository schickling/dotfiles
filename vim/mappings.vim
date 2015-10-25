" splits
"nnoremap <silent> vv <C-w>v
"nnoremap <silent> ss <C-w>s

" format the entire file
nnoremap <leader>fef :normal! gg=G``<CR>
nnoremap <silent> <leader>x :call JsBeautify()<cr>

nnoremap <silent> <leader>tt :TagbarToggle<CR>

" Wrapped lines goes down/up to next row, rather than next line in file.
noremap j gj
noremap k gk
nnoremap <leader>a :call NERDComment('n', 'Toggle')<CR>
vnoremap <leader>a :call NERDComment('x', 'Toggle')<CR>

vmap v <Plug>(expand_region_expand)
vmap <C-v> <Plug>(expand_region_shrink)

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
noremap <leader>l :bn<CR>
noremap <leader>h :bp<CR>
noremap <leader>n :bp<bar>bd #<CR>
noremap <leader>b :BufOnly<CR>
noremap <leader><leader> :e #<CR>

nnoremap <Leader>o :CtrlP<CR>
nnoremap <Leader>w :w<CR>

" quick close
map Q :wqa<CR>

" clear search highlight
noremap <leader>/ :nohl<CR>

" toggle color schema
noremap <leader>] :ToggleBackground<CR>

" fugitive (git)
noremap <leader>g :Gstatus<CR>

" vpaste
map <leader>\ :exe "w !vpaste ft=".&ft<CR><CR>
vmap <leader>\ <ESC>:exe "'<,'>w !vpaste ft=".&ft<CR><CR>

" Yank text to the OS X clipboard
noremap <leader>y "*y
noremap <leader>yy "*Y

" Preserve indentation while pasting text from the OS X clipboard
noremap <leader>p :set paste<CR>:put  *<CR>:set nopaste<CR>
