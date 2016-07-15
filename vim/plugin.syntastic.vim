if filereadable(".eslintrc")
  let g:syntastic_javascript_checkers = ['eslint']
endif

let g:syntastic_mode_map = {
      \'mode': 'active',
      \ 'passive_filetypes': ['go'] }

let g:tsuquyomi_disable_quickfix = 1
let g:syntastic_typescript_checkers = ['tsuquyomi']
