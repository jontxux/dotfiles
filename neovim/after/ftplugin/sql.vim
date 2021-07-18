if executable('sqlformat')
    setlocal formatprg=sqlformat\ -k\ upper\ -r\ %
endif
