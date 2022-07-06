map <C-e> :NERDTreeToggle<CR>:NERDTreeMirror<CR>

let NERDTreeShowHidden=1
let NERDTreeIgnore=['\.pyc', '\~$', '\.swo$', '\.swp$', '\.git$', '\.hg', '\.svn', '\.bzr', '\.DS_Store$', '\.tmp', '__pycache__', '.ropeproject']

" Make nerdtree look nice
let NERDTreeMinimalUI = 1
let NERDTreeDirArrows = 1
let g:NERDTreeWinSize = 30

let NERDTreeMapOpenVSplit = 'v'
let NERDTreeMapOpenSplit = 's'
