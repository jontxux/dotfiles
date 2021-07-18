nnoremap <buffer> <F5> :w<CR>:!javac % && java -enableassertions %:p<CR>
setlocal shiftwidth=4
setlocal tabstop=4
setlocal foldmethod=syntax
setlocal colorcolumn=120
setlocal noexpandtab
if executable('astyle')
    setlocal formatprg=astyle\ -t\ -p\ -j
endif
