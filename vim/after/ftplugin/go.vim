nnoremap <buffer> <F5> :GoRun<CR>
nnoremap <buffer> <F3> :GoDebugStart<CR>
" Se ejecuta despues de haber empezado el debugger :GoDebugStart
let g:go_debug_mappings = {
 \ '(go-debug-continue)':   {'key': '<F4>'},
 \ '(go-debug-print)':      {'key': '<F6>'},
 \ '(go-debug-breakpoint)': {'key': '<F9>'},
 \ '(go-debug-next)':       {'key': '<F10>'},
 \ '(go-debug-step)':       {'key': '<F7>'},
 \ '(go-debug-halt)':       {'key': '<F8>'},
\ }

setlocal shiftwidth=4
setlocal tabstop=4
setlocal colorcolumn=80
setlocal noexpandtab
setlocal foldmethod=syntax
