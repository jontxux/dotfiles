nnoremap <buffer> <F5> :w<CR>:!g++ -std=c++17 -O2 % -o %:r.out && ./%:r.out<CR>

setlocal shiftwidth=4
setlocal tabstop=4
setlocal colorcolumn=80
setlocal noexpandtab
setlocal foldmethod=syntax
if executable('clang-format')
    setlocal formatprg=clang-format
endif
