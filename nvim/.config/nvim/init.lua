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

  use { 'Swoogan/nightfox.nvim', branch = "konsole" } -- theme

  use 'neovim/nvim-lspconfig'  -- Easy configuration of LSP
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' } -- incremental language parser
  use { 'nvim-treesitter/nvim-treesitter-textobjects' } -- Additional textobjects for treesitter
  -- use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate', branch = '0.5-compat' } -- incremental language parser
  -- use { 'nvim-treesitter/nvim-treesitter-textobjects', branch = '0.5-compat' } -- Additional textobjects for treesitter
  use 'nvim-treesitter/playground'

  use 'mfussenegger/nvim-dap'

  use 'hrsh7th/nvim-compe'  -- Autocomplete
  use { 'nvim-telescope/telescope.nvim', requires = { 'nvim-lua/plenary.nvim' } }  -- Fuzzy finder
  use 'prettier/vim-prettier'  -- Run prettier formatting for javascript/typescript
  use { 
      'kyazdani42/nvim-tree.lua',
      requires = {'kyazdani42/nvim-web-devicons'},
      config = function() require('nvim-tree').setup {} end
  }  -- Filesystem viewer
  use 'editorconfig/editorconfig-vim'

  use 'tpope/vim-commentary' -- toggle comments
  -- use 'b3nj5m1n/kommentary'
  -- Comment stuff out. Use gcc to comment out a line (takes a count), gc to comment out the target of a motion (for example, gcap to comment out a paragraph), gc in visual mode to comment out the selection, and gc in operator pending mode to target a comment. You can also use it as a command, either with a range like :7,17Commentary, or as part of a :global invocation like with :g/TODO/Commentary.
  
  use 'machakann/vim-sandwich' -- add, delete, replace pairs (like {}, (), "")
  use 'hoob3rt/lualine.nvim' -- Fancier statusline
 
  -- use 'tpope/vim-unimpaired' 
  use 'tpope/vim-dispatch' -- Async task runner
  use 'L3MON4D3/LuaSnip' -- Snippets plugin
  use 'rafamadriz/friendly-snippets'  -- Premade snippets
  use 'AndrewRadev/tagalong.vim' -- HTML tag manipulation (eg: edit in tag, <|div></div> ciwspan -> <span></span>
end)

local cmd = vim.cmd
local indent = 4
local opts = { noremap=true, silent=true }

-- Setup Language sever protocol
local nvim_lsp = require('lspconfig')

local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  --Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)


  -- buf_set_keymap('n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  -- buf_set_keymap('n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  -- buf_set_keymap('n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)

  -- buf_set_keymap(bufnr, 'v', '<leader>ca', '<cmd>lua vim.lsp.buf.range_code_action()<CR>', opts)
 
  -- TODO: unify these keypresses
  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', '<leader>sh', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap("n", "<leader>f", '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
  buf_set_keymap('n', '<leader>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_set_keymap('n', '<leader>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap('n', '<leader>so', [[<cmd>lua require('telescope.builtin').lsp_document_symbols()<CR>]], opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)

end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = {
    'documentation',
    'detail',
    'additionalTextEdits',
  }
}

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
-- local servers = { "pyright", "rust_analyzer", "tsserver" }

local servers = { "tsserver" }
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup {
    capabilities = capabilities,
    on_attach = on_attach,
    flags = {
      debounce_text_changes = 150,
    }
  }
end

-- Setup OmniSharp
local pid = vim.fn.getpid()

nvim_lsp['omnisharp'].setup {
  capabilities = capabilities,
  on_attach = on_attach,
  flags = {
    debounce_text_changes = 150,
  },
  cmd = { vim.env.OMNISHARP, "--languageserver" , "--hostPID", tostring(pid), "formattingOptions:EnableEditorConfigSupport=true" }
}

-- Setup auto compeletion
vim.o.completeopt = "menuone,noselect"

require('compe').setup {
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
    spell = true;
    nvim_lsp = true;
    nvim_lua = true;
    luasnip = true;
    treesitter = false;
  };
}

--Set statusbar
require('lualine').setup {
  options = {
    -- ... your lualine config
    theme = "nightfox"
  }
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
      scope_incremental = 'grc',
      node_incremental = 'grn',
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
        ["in"] = {
          c_sharp = "(namespace_declaration body: (_) @namespace.inner)",
        },
        ["an"] = {
          c_sharp = "(namespace_declaration) @namespace.outer",
        },
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        [']]'] = '@class.outer',
        [']m'] = '@function.outer',
        [']a'] = '@parameter.inner',
      },
      goto_previous_start = {
        ['[['] = '@class.outer',
        ['[m'] = '@function.outer',
        ['[a'] = '@parameter.inner',
      },
      goto_next_end = {
        [']}'] = '@class.outer',
        [']M'] = '@function.outer',
        [']A'] = '@parameter.outer',
      },
      goto_previous_end = {
        ['[{'] = '@class.outer',
        ['[M'] = '@function.outer',
        ['[A'] = '@parameter.outer',
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

local dap = require("dap")
dap.adapters.netcoredbg = {
  type = 'executable',
  command = vim.env.DEV_HOME .. 'netcoredbg/netcoredbg',
  args = {'--interpreter=vscode'}
}

dap.configurations.cs = {
  {
    type = "netcoredbg",
    name = "launch - netcoredbg",
    request = "launch",
    program = function()
        return vim.fn.input('Path to dll', vim.fn.getcwd() .. '/bin/Debug/net5.0', 'file')
    end,
  },
}

-- Setup Theme
local foxxy = require('nightfox')

-- Load the colorscheme
foxxy.setup({
    styles = {
        comments = "italic"
    }
})

foxxy.load()

-- Pretty Icons
require('nvim-web-devicons').setup {
 -- globally enable default icons (default to false)
 -- will get overriden by `get_icons` option
 default = true;
}

-- *** Start luasnips
local function prequire(...)
local status, lib = pcall(require, ...)
if (status) then return lib end
    return nil
end

local luasnip = prequire('luasnip')

luasnip.config.set_config({history = false})

local t = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local check_back_space = function()
    local col = vim.fn.col('.') - 1
    if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
        return true
    else
        return false
    end
end

_G.tab_complete = function()
    if luasnip and luasnip.expand_or_jumpable() then
        return t("<Plug>luasnip-expand-or-jump")
    elseif check_back_space() then
        return t "<Tab>"
    else
        return vim.fn['compe#complete']()
    end
    return ""
end
_G.s_tab_complete = function()
    if vim.fn.pumvisible() == 1 then
        return t "<C-p>"
    elseif luasnip and luasnip.jumpable(-1) then
        return t("<Plug>luasnip-jump-prev")
    else
        return t "<S-Tab>"
    end
    return ""
end

vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})

local s = luasnip.snippet
local sn = luasnip.snippet_node
local t = luasnip.text_node
local i = luasnip.insert_node
local f = luasnip.function_node
local c = luasnip.choice_node
local d = luasnip.dynamic_node

luasnip.snippets = {
    cs = {
        s("sum", { 
            t({"/// <summary>", "/// "}),
            i(0),
            t({"", "/// </summary>"}),
        }),
        s("pra", {
            t("<parameter name=\""),
            i(1, "name"),
            t("\">"),
            i(0),
            t("</parameter>"),
        }),
        s({trig = "try", name = "Try log", dscr = "Try catch, log the exception"}, { 
            t({"try", "{", "\t"}),
            i(0),
            t({"","}", "catch ("}),
            i(1, "Exception"),
            t(" e)"),
            t({"", "{", "\t_logger.LogError(e, \""}),
            i(2),
            t({"\");", "}"}),
        }),
    }
}

require("luasnip/loaders/from_vscode").lazy_load()

-- *** End luasnips

require('nvim-tree').setup({})

local os_uname = vim.loop.os_uname()
local is_windows = os_uname.sysname == "Windows_NT"
if is_windows then
  -- vim.opt.shell = "pwsh"
end

-- Vim options
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
vim.opt.wrap = false

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

vim.api.nvim_set_keymap('', '<Space>', '<Nop>', opts)
vim.g.mapleader = ','
vim.g.maplocalleader = ','


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

vim.api.nvim_set_keymap('n', '<leader>cp', [[<cmd>echohl WarningMsg | echo "Use <leader>sf (search files)" | lua require('telescope.builtin').find_files({previewer = false})<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>rg', [[<cmd>echohl WarningMsg | echo "Use <leader>sg (search - grep)" | lua require('telescope.builtin').live_grep()<CR>]], opts)

-- Add telescope shortcuts
vim.api.nvim_set_keymap('n', '<leader><space>', [[<cmd>lua require('telescope.builtin').buffers()<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>sf', [[<cmd>lua require('telescope.builtin').find_files({previewer = false})<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>sb', [[<cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>sh', [[<cmd>lua require('telescope.builtin').help_tags()<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>sg', [[<cmd>lua require('telescope.builtin').live_grep()<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>sd', [[<cmd>lua require('telescope.builtin').grep_string()<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>?', [[<cmd>lua require('telescope.builtin').oldfiles()<CR>]], opts)

-- Buffer Mappings
-- Close current buffer
vim.api.nvim_set_keymap('n', '<leader>bd', [[<cmd>bd<CR>]], opts)
-- Swap buffer
vim.api.nvim_set_keymap('n', '<leader>bs', [[<cmd>b#<CR>]], opts)
-- vim.api.nvim_set_keymap('n', '<leader><leader>', [[<cmd>b#<CR>]], opts)
-- Close current buffer and switch to last used
vim.api.nvim_set_keymap('n', '<leader>bq', [[<cmd>b#|bd#<CR>]], opts)

-- launch a terminal
vim.api.nvim_set_keymap('n', '<leader>t', [[<cmd>10split | term<CR>a]], opts)

-- treat - seperated words as a word object
vim.api.nvim_exec([[ set iskeyword+=- ]], false)
-- treat _ seperated words as a word object  
vim.api.nvim_exec([[ set iskeyword+=_ ]], false)

vim.api.nvim_exec(
  [[

" launch a terminal
if has('win32') || has('win64')
    noremap <Leader>t :10split\|term pwsh<Cr>a
else
    noremap <Leader>t :10split\|term<Cr>a
endif

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

augroup cs
  autocmd!
  autocmd BufNewFile,BufRead *.cs compiler dotnet
augroup END

au BufReadPost *.zig set ft=zig

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

" Remap keys in terminal mode
tnoremap <Esc> <C-\><C-n>
tnoremap <M-[> <Esc>
tnoremap <C-v><Esc> <Esc>

nnoremap <C-n> :NvimTreeToggle<CR>
nnoremap <leader>r :NvimTreeRefresh<CR>
nnoremap <leader>n :NvimTreeFindFile<CR>

" Compe keybindings
inoremap <silent><expr> <C-Space> compe#complete()
inoremap <silent><expr> <CR>      compe#confirm('<CR>')
inoremap <silent><expr> <C-e>     compe#close('<C-e>')
inoremap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 })
inoremap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 })
inoremap </ </<C-N>

"" Functions

" Setup cache directory so .swp files aren't in the cwd
if !isdirectory(expand("$HOME/.cache/nvim/swap"))
  call mkdir(expand("$HOME/.cache/nvim/swap"), "p")
endif
set directory=$HOME/.cache/nvim/swap

command! DiffOrig vertical new | set buftype=nofile | read # | 0d_ | diffthis | wincmd p | diffthis

]],
  false
)

