setlocal shiftwidth=2
setlocal tabstop=2
setlocal colorcolumn=80
setlocal noexpandtab
if has('python3')
    setlocal formatprg=python3\ -m\ json.tool
elseif executable('jq') && executable('cat')
    setlocal formatprg=cat\ %\ \|\ jq
endif
