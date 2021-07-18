nnoremap <buffer> <F5> :w<CR>:!python3 %<CR>
setlocal shiftwidth=4
setlocal tabstop=4
setlocal colorcolumn=80
setlocal expandtab
if executable('yapf')
    setlocal formatprg=yapf
endif
