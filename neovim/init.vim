call plug#begin('~/.local/share/nvim/plugged')

Plug 'easymotion/vim-easymotion'
Plug 'scrooloose/nerdtree'
" Plug 'jiangmiao/auto-pairs'
Plug 'windwp/nvim-autopairs'
Plug 'tpope/vim-commentary'
Plug 'vim-airline/vim-airline'
let g:airline#extensions#tabline#enabled = 1
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'hrsh7th/vim-vsnip' 
" Expand
imap <expr> <C-y>   vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-j>'
smap <expr> <C-y>   vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-j>'

" Expand or jump
imap <expr> <C-l>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>'
smap <expr> <C-l>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>'

" Jump forward or backward
imap <expr> <C-j>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
smap <expr> <C-j>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
imap <expr> <C-k> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
smap <expr> <C-k> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'   
Plug 'cstrap/python-snippets' 
Plug 'ylcnfrht/vscode-python-snippet-pack' 
Plug 'xabikos/vscode-javascript' 
Plug 'golang/vscode-go' 
Plug 'rust-lang/vscode-rust' 

" Plug 'SirVer/ultisnips'
" let g:UltiSnipsExpandTrigger="<c-y>"
" let g:UltiSnipsJumpForwardTrigger="<c-j>"
" let g:UltiSnipsJumpBackwardTrigger="<c-k>"
Plug 'tpope/vim-surround'
Plug 'ryanoasis/vim-devicons'
Plug 'sheerun/vim-polyglot'
Plug 'tpope/vim-repeat'
Plug 'majutsushi/tagbar'
Plug 'vimwiki/vimwiki'
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-compe'
Plug 'RRethy/vim-illuminate'

Plug 'fatih/vim-go'
let g:go_doc_keywordprg_enabled = 0
let g:go_highlight_function_calls = 1
let g:go_highlight_array_whitespace_error = 1
let g:go_highlight_chan_whitespace_error = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_space_tab_error = 1
let g:go_highlight_trailing_whitespace_error = 1
let g:go_highlight_operators = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_parameters = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_generate_tags = 0
let g:go_highlight_string_spellcheck = 1
let g:go_highlight_format_strings = 1
let g:go_highlight_variable_declarations = 1
let g:go_highlight_variable_assignments = 1
let g:go_highlight_diagnostic_errors = 1
let g:go_highlight_diagnostic_warnings = 1
let g:go_highlight_operators = 1

Plug 'morhetz/gruvbox'

call plug#end()

set mouse=a
set number
set relativenumber
set cursorline
set clipboard=unnamed,unnamedplus


set nowrap "Para que la linea se quede entera
set nofoldenable "Al iniciar todo desplegado
set noshowmode "Con airline no hace falta modo


set ignorecase "busquedas no distinguen mayusculas y minusculas
set incsearch   "Muestra la concordancia de una busqueda mientras escribes.
set hlsearch    "Resalta las busquedas

set background=dark
colorscheme gruvbox

let mapleader = ","


cnoreabbrev W w
cnoreabbrev W! w!
cnoreabbrev Q! q!
cnoreabbrev Qall! qall!
cnoreabbrev Wq wq
cnoreabbrev Wa wa
cnoreabbrev wQ wq
cnoreabbrev WQ wq
cnoreabbrev Q q
cnoreabbrev Qall qall


tnoremap <Esc> <C-\><C-n>
nnoremap <F11> :NERDTreeToggle<CR>
nnoremap <F12> :TagbarToggle<CR>

nnoremap <silent> <C-l> :bn!<CR>
nnoremap <silent> <C-h> :bp!<CR>
nnoremap ññ :b#<CR>
nnoremap ñd :bd<CR>
nnoremap ñD :bd!<CR>

nnoremap <C-p> :Files<CR>
nnoremap ñh :noh<CR>

nnoremap ñv :e $MYVIMRC<CR>
nnoremap ñV :so $MYVIMRC<CR>

augroup highlight_yank
    autocmd!
    autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank("IncSearch", 1000)
augroup END

lua << EOF
require('nvim-autopairs').setup()
EOF

lua << EOF
local nvim_lsp = require('lspconfig')

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  --Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<leader>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<leader>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap("n", "<leader>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)

end

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers = { "clangd", "gopls", "vimls", "pyright", "bashls" }
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup {
    on_attach = on_attach,
    flags = {
      debounce_text_changes = 150,
    }
  }
end
EOF

set completeopt=menuone,noselect

" lua << EOF
" -- Compe setup
" require'compe'.setup {
"   enabled = true;
"   autocomplete = true;
"   debug = false;
"   min_length = 1;
"   preselect = 'enable';
"   throttle_time = 80;
"   source_timeout = 200;
"   incomplete_delay = 400;
"   max_abbr_width = 100;
"   max_kind_width = 100;
"   max_menu_width = 100;
"   documentation = true;

"   source = {
"     path = true;
"     nvim_lsp = true;
"   };
" }

" local t = function(str)
"   return vim.api.nvim_replace_termcodes(str, true, true, true)
" end

" local check_back_space = function()
"     local col = vim.fn.col('.') - 1
"     if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
"         return true
"     else
"         return false
"     end
" end

" -- Use (s-)tab to:
" --- move to prev/next item in completion menuone
" --- jump to prev/next snippet's placeholder
" _G.tab_complete = function()
"   if vim.fn.pumvisible() == 1 then
"     return t "<C-n>"
"   elseif check_back_space() then
"     return t "<Tab>"
"   else
"     return vim.fn['compe#complete']()
"   end
" end
" _G.s_tab_complete = function()
"   if vim.fn.pumvisible() == 1 then
"     return t "<C-p>"
"   else
"     return t "<S-Tab>"
"   end
" end

" vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
" vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
" vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
" vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
" EOF
lua << EOF
require'compe'.setup {
  enabled = true;
  autocomplete = true;
  debug = false;
  min_length = 1;
  preselect = 'enable';
  throttle_time = 80;
  source_timeout = 200;
  resolve_timeout = 800;
  incomplete_delay = 400;
  max_abbr_width = 100;
  max_kind_width = 100;
  max_menu_width = 100;
  documentation = {
    border = { '', '' ,'', ' ', '', '', '', ' ' }, -- the border option is the same as `|help nvim_open_win|`
    winhighlight = "NormalFloat:CompeDocumentation,FloatBorder:CompeDocumentationBorder",
    max_width = 120,
    min_width = 60,
    max_height = math.floor(vim.o.lines * 0.3),
    min_height = 1,
  };

  source = {
    path = true;
    buffer = true;
    calc = true;
    nvim_lsp = true;
    nvim_lua = true;
    vsnip = true;
    ultisnips = true;
    luasnip = true;
  };
}

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = {
    'documentation',
    'detail',
    'additionalTextEdits',
  }
}

require'lspconfig'.rust_analyzer.setup {
  capabilities = capabilities,
}

EOF
