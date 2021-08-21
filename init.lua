-- Install packer
local install_path = vim.fn.stdpath 'data' .. '/site/pack/packer/start/packer.nvim'

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  vim.fn.execute('!git clone https://github.com/wbthomason/packer.nvim ' .. install_path)
end

vim.api.nvim_exec([[
  augroup Packer
    autocmd!
    autocmd BufWritePost init.lua PackerCompile
  augroup end
]], false)

local use = require('packer').use
require('packer').startup(function()
  use 'wbthomason/packer.nvim' -- Package manager

  use 'EdenEast/nightfox.nvim' -- theme
  -- use 'lokaltog/vim-distinguished'

  use 'nvim-treesitter/playground'

  use 'tpope/vim-commentary' -- toggle comments
  -- use 'b3nj5m1n/kommentary'
  -- Comment stuff out. Use gcc to comment out a line (takes a count), gc to comment out the target of a motion (for example, gcap to comment out a paragraph), gc in visual mode to comment out the selection, and gc in operator pending mode to target a comment. You can also use it as a command, either with a range like :7,17Commentary, or as part of a :global invocation like with :g/TODO/Commentary.
  
  use 'machakann/vim-sandwich' -- add, delete, replace pairs (like {}, (), "")

  use 'itchyny/lightline.vim' -- Fancier statusline

  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate', branch = '0.5-compat' } -- incremental language parser
  use { 'nvim-treesitter/nvim-treesitter-textobjects', branch = '0.5-compat' } -- Additional textobjects for treesitter

  -- use 'L3MON4D3/LuaSnip' -- Snippets plugin
  use 'editorconfig/editorconfig-vim'

  use 'neovim/nvim-lspconfig'
  use 'hrsh7th/nvim-compe'

  -- use 'tpope/vim-unimpaired' 
  
  use { 'nvim-telescope/telescope.nvim', requires = { 'nvim-lua/plenary.nvim' } }

  use { 'kyazdani42/nvim-tree.lua', requires = {'kyazdani42/nvim-web-devicons'} }
end)

local cmd = vim.cmd
local indent = 4

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
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)

  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  -- buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)

  -- buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  -- buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  -- buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)

  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)

end

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
-- local servers = { "pyright", "rust_analyzer", "tsserver" }

local servers = { "tsserver" }
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup {
    on_attach = on_attach,
    flags = {
      debounce_text_changes = 150,
    }
  }
end

-- 

local pid = vim.fn.getpid()
local omnisharp_bin = vim.env.DEV_HOME .. "/omnisharp-win-x64/OmniSharp.exe"

nvim_lsp['omnisharp'].setup {
  on_attach = on_attach,
  flags = {
    debounce_text_changes = 150,
  },
  cmd = { omnisharp_bin, "--languageserver" , "--hostPID", tostring(pid), "formattingOptions:EnableEditorConfigSupport=true" }
}

vim.o.completeopt = "menuone,noselect"

require'compe'.setup {
  enabled = true;
  autocomplete = true;
  debug = false;
  min_length = 1;
  preselect = 'always';
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

--Set statusbar
vim.g.lightline = {
  colorscheme = 'nightfox',
  active = { left = { { 'mode', 'paste' }, { 'readonly', 'filename', 'modified' } } },
--  active = { left = { { 'mode', 'paste' }, { 'gitbranch', 'readonly', 'filename', 'modified' } } },
--  component_function = { gitbranch = 'fugitive#head' },
}

-- Treesitter configuration
-- Parsers must be installed manually via :TSInstall
require('nvim-treesitter.configs').setup {
  highlight = {
    enable = true, -- false will disable the whole extension
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = 'gnn',
      node_incremental = 'grn',
      scope_incremental = 'grc',
      node_decremental = 'grm',
    },
  },
  indent = {
    enable = true,
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ["ia"] = "@parameter.inner",
        ["aa"] = "@parameter.outer",
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        [']m'] = '@function.outer',
        [']]'] = '@class.outer',
      },
      goto_next_end = {
        [']M'] = '@function.outer',
        [']['] = '@class.outer',
      },
      goto_previous_start = {
        ['[m'] = '@function.outer',
        ['[['] = '@class.outer',
      },
      goto_previous_end = {
        ['[M'] = '@function.outer',
        ['[]'] = '@class.outer',
      },
    },
  },
  playground = {
    enable = true,
    disable = {},
    updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
    persist_queries = false, -- Whether the query persists across vim sessions
    keybindings = {
      toggle_query_editor = 'o',
      toggle_hl_groups = 'i',
      toggle_injected_languages = 't',
      toggle_anonymous_nodes = 'a',
      toggle_language_display = 'I',
      focus_language = 'f',
      unfocus_language = 'F',
      update = 'R',
      goto_node = '<cr>',
      show_help = '?',
    },
  },
}

vim.opt.background = "dark"
vim.opt.termguicolors = true
vim.opt.number = true               -- show the current line number (w/ relative on)
vim.opt.relativenumber = true       -- show relative line numbers
vim.opt.splitbelow = true           -- new horizontal windows appear on the bottom
vim.opt.splitright = true           -- new vertical windows appear on the right
vim.opt.smartindent = true
vim.opt.cursorline = true           -- highlights current line
vim.opt.hidden = true
vim.opt.smartcase = true            -- searching case insensitive unless mixed case
vim.opt.ignorecase = true

vim.opt.tabstop = 8
vim.opt.sts = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true       -- converts tab presses to spaces
vim.opt.inccommand = 'nosplit'    -- shows effects of substitutions 
vim.opt.mouse = 'a'

--Save undo history
vim.cmd [[set undofile]]

--Decrease update time
vim.opt.updatetime = 250
vim.opt.signcolumn = 'yes'

vim.api.nvim_set_keymap('', '<Space>', '<Nop>', { noremap = true, silent = true })
vim.g.mapleader = ','
vim.g.maplocalleader = ','

-- vim.g.nightfox_style = "nordfox"
vim.g.nightfox_color_delimiter = "red"
vim.g.nightfox_italic_comments = 1

-- Load the colorscheme
require('nightfox').set()

-- Highlight on yank
vim.api.nvim_exec(
  [[
  augroup YankHighlight
    autocmd!
    autocmd TextYankPost * silent! lua vim.highlight.on_yank()
  augroup end
]],
  false
)

-- Y yank until the end of line
vim.api.nvim_set_keymap('n', 'Y', 'y$', { noremap = true })

vim.api.nvim_set_keymap('n', '<leader>cp', [[<cmd>lua require('telescope.builtin').find_files({previewer = false})<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>rg', [[<cmd>lua require('telescope.builtin').live_grep()<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader><space>', [[<cmd>lua require('telescope.builtin').buffers()<CR>]], { noremap = true, silent = true })

--Add telescope shortcuts
-- vim.api.nvim_set_keymap('n', '<leader><space>', [[<cmd>lua require('telescope.builtin').buffers()<CR>]], { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<leader>sf', [[<cmd>lua require('telescope.builtin').find_files({previewer = false})<CR>]], { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<leader>sb', [[<cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<CR>]], { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<leader>sh', [[<cmd>lua require('telescope.builtin').help_tags()<CR>]], { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<leader>st', [[<cmd>lua require('telescope.builtin').tags()<CR>]], { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<leader>sd', [[<cmd>lua require('telescope.builtin').grep_string()<CR>]], { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<leader>sp', [[<cmd>lua require('telescope.builtin').live_grep()<CR>]], { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<leader>so', [[<cmd>lua require('telescope.builtin').tags{ only_current_buffer = true }<CR>]], { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<leader>?', [[<cmd>lua require('telescope.builtin').oldfiles()<CR>]], { noremap = true, silent = true })

-- " Using Lua functions
-- nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>
-- nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>
-- nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>
-- nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>

vim.api.nvim_exec(
  [[
      let g:lightline = {'colorscheme': 'nightfox'}

" set nowritebackup   " Prevent vim from writing to new files every time
set iskeyword+=-    " treat - seperated words as a word object
set iskeyword+=_    " treat _ seperated words as a word object


let g:sandwich#recipes = deepcopy(g:sandwich#default_recipes)
" Add: Press sa{motion/textobject}{addition}. For example, a key sequence saiw( makes foo to (foo).
" Delete: Press sdb or sd{deletion}. For example, key sequences sdb or sd( makes (foo) to foo. sdb searches a set of surrounding automatically.
" Replace: Press srb{addition} or sr{deletion}{addition}. For example, key sequences srb" or sr(" makes (foo) to "foo".

" Auto commands
augroup numbertoggle
    autocmd!
    autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
    autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
augroup END

augroup markdown
  autocmd!
  autocmd BufNewFile,BufRead *.md setlocal wrap spell
augroup END

augroup zig
  autocmd!
  autocmd FileType zig :iabbrev <buffer> oom return error.OutOfMemory; 
augroup END

"" Mappings

"" Simplified window management
map <C-h> <C-W>h
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-l> <C-W>l

" launch a terminal
if has('win32') || has('win64')
    noremap <Leader>t :10split\|term://powershell<Cr>a
else
    noremap <Leader>t :10split\|term<Cr>a
endif 

"" Custom
" Repeats the character under the cursor
noremap <Leader>r ylp
" Removes search highlighting
noremap <Leader>nl :nohl<Cr>
" Save file
nnoremap <leader>w <Esc>:w<cr>
" Save and quit
nnoremap <leader>x <Esc>:x<cr>

" Yanks selection to system clipboard
nnoremap <Leader>y "+y
" Yanks selection to system clipboard
vnoremap <Leader>y "+y  
" Yanks line to system clipboard
nnoremap <Leader>yy "+yy 
" Pastes from system clipboard
nnoremap <Leader>p "+p
" Pastes from system clipboard
nnoremap <Leader>P "+P

" Edit vim config in split
nnoremap <Leader>ec :vsplit $MYVIMRC<Cr>
" Source vim config
nnoremap <Leader>sc :source $MYVIMRC<Cr>

" Switch buffers
nnoremap <Leader>bb :ls<CR>:b<Space>
" Close current buffer
nnoremap <Leader>bd :bd<CR>
" Swap Buffer
nnoremap <Leader>bs :b#<CR>
nnoremap <Leader>bq :b#\|bd#<CR>

" Remap keys in terminal mode
tnoremap <Esc> <C-\><C-n>
tnoremap <M-[> <Esc>
tnoremap <C-v><Esc> <Esc>

nnoremap <C-n> :NvimTreeToggle<CR>
nnoremap <leader>r :NvimTreeRefresh<CR>
nnoremap <leader>n :NvimTreeFindFile<CR>

"" Functions

" Setup cache directory so .swp files aren't in the cwd
if !isdirectory(expand("$HOME/.cache/vim/swap"))
  call mkdir(expand("$HOME/.cache/vim/swap"), "p")
endif
set directory=$HOME/.cache/vim/swap

command! DiffOrig vertical new | set buftype=nofile | read # | 0d_ | diffthis | wincmd p | diffthis

]],
  false
)
