setlocal shiftwidth=4
setlocal tabstop=4
setlocal foldmethod=syntax
setlocal colorcolumn=80
setlocal noexpandtab
if executable('astyle')
    setlocal formatprg=astyle\ -t\ -A3\ -p\ -j\ -k3\ -W3\ -xU\ -xW\ -xC80
elseif executable('clang-format')
    setlocal formatprg=clang-format
endif
