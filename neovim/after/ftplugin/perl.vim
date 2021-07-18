nnoremap <buffer> <F5> :w<CR>:!perl %<CR>
nnoremap <buffer> <F6> :w<CR>:split<CR>:!perl -MDB::Color -d %<CR>
setlocal keywordprg=perldoc\ -f
setlocal shiftwidth=4
setlocal tabstop=4
setlocal colorcolumn=80
setlocal noexpandtab

if executable('perltidy')
    setlocal formatprg=perltidy\ -et=4
endif
