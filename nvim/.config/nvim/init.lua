local plugins = require("plugins")
plugins.init() -- Install packer if not exists and setup commands and autocmds
plugins.load() -- Load packer with the packer spec

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
  -- buf_set_keymap('n', 'gr', '<cmd>lua require(\'omnisharp_extended\').telescope_lsp_definitions()<CR>', opts)


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

-- local capabilities = vim.lsp.protocol.make_client_capabilities()
local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
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

local servers = { "pyright", "rust_analyzer", "tsserver", "clangd" }
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
  handlers = {
    ["textDocument/definition"] = require('omnisharp_extended').handler,
  },
  capabilities = capabilities,
  on_attach = on_attach,
  flags = {
    debounce_text_changes = 150,
  },
  cmd = { vim.env.OMNISHARP, "--languageserver" , "--hostPID", tostring(pid), "formattingOptions:EnableEditorConfigSupport=true" }
}


-- Setup auto compeletion
vim.o.completeopt = "menu,menuone,noselect"

-- Setup nvim-cmp.
local cmp = require('cmp')

cmp.setup({
    snippet = {
      expand = function(args)
	require('luasnip').lsp_expand(args.body) 
      end,
    },
    mapping = {
      ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
      ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
      ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
      ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
      ['<C-e>'] = cmp.mapping({
	i = cmp.mapping.abort(),
	c = cmp.mapping.close(),
      }),
      ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    },
    sources = cmp.config.sources({
	    { name = 'nvim_lsp' },
	    { name = 'luasnip' },
    }, {
	    { name = 'buffer' },
    }),
    completion = { keyword_length = 3 }
})

-- Set configuration for specific filetype.
--    cmp.setup.filetype('gitcommit', {
    -- sources = cmp.config.sources({
    -- { name = 'cmp_git' }, -- You can specify the `cmp_git` source if you were installed it. 
    -- }, {
    --     { name = 'buffer' },
    --     })
--    })

-- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline('/', {
sources = {
  { name = 'buffer' }
}
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
sources = cmp.config.sources({
  { name = 'path' }
}, {
  { name = 'cmdline' }
})
})

-- -- Setup lspconfig.
-- local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
-- -- Replace <YOUR_LSP_SERVER> with each lsp server you've enabled.
-- require('lspconfig')['omnisharp'].setup {
--     capabilities = capabilities
-- }
-- require('lspconfig')['tsserver'].setup {
--     capabilities = capabilities
-- }

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

-- dap virtual text
require('nvim-dap-virtual-text').setup {
    enabled = true,                     -- enable this plugin (the default)
    enabled_commands = true,            -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
    highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
    highlight_new_as_changed = false,   -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
    show_stop_reason = true,            -- show stop reason when stopped for exceptions
    commented = false,                  -- prefix virtual text with comment string
}

-- DAP
local dap = require('dap')

vim.fn.sign_define('DapBreakpoint', {text='🛑', texthl='', linehl='', numhl=''})
vim.fn.sign_define('DapBreakpointRejected', {text='⛔', texthl='', linehl='', numhl=''})

dap.adapters.coreclr = {
  type = 'executable',
  command = vim.env.DEV_HOME .. '/.tools/netcoredbg/netcoredbg',
  args = {'--interpreter=vscode'}
}

dap.configurations.cs = {
  {
    type = "coreclr",
    name = "launch - netcoredbg",
    request = "launch",
    program = function()
        return vim.fn.input('Path to dll', vim.fn.getcwd() .. '/bin/Debug/net5.0', 'file')
    end,
  },
}

-- adds loading of .vscode/launch.json files
require('dap.ext.vscode').load_launchjs()

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
local cmp = prequire("cmp")

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
        cmp.complete()
    end
    return ""
end
_G.s_tab_complete = function()
    if luasnip and luasnip.jumpable(-1) then
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

-- Takes user input and replaces space with underscore, capitalizes each word
-- Ex. "this is a test method" => "This_Is_A_Test_Method"
_G.transform_test_name = function()
    local input = vim.fn.input("Message: ")
    local output = {}
    for i in string.gmatch(input, "%S+") do
        local first = string.sub(i, 1, 1)
        local rest = string.sub(i, 2, string.len(i))
        local up = string.upper(first)
        table.insert(output, up .. rest)
    end

    local result = ''

    for k,v in pairs(output) do
       result = result .. v .. '_'
    end
    
    result = string.sub(result, 1, -2)

    local win = vim.api.nvim_get_current_win()
    local bufnr = vim.api.nvim_get_current_buf()
    local cur = vim.api.nvim_win_get_cursor(win)
    local start_row = cur[1] - 1
    local start_col = cur[2] + 1
    vim.api.nvim_buf_set_text(bufnr, start_row, start_col, start_row, start_col, {result})

    local new_col = start_col + string.len(result)
    vim.api.nvim_win_set_cursor(win, {start_row + 1, new_col})
end

-- global keymap
vim.api.nvim_set_keymap("n", "<leader>tt", [[<cmd>lua transform_test_name()<cr>]], opts)

-- *** CONFIG *** --

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

vim.opt.tabstop = 4
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


-- -- Highlight on yank
vim.api.nvim_exec(
  [[
  augroup YankHighlight
    autocmd!
    autocmd TextYankPost * silent! lua vim.highlight.on_yank()
  augroup end
]],
  false
)

-- Add telescope shortcuts
vim.api.nvim_set_keymap('n', '<leader><space>', [[<cmd>lua require('telescope.builtin').buffers()<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>sf', [[<cmd>lua require('telescope.builtin').find_files({previewer = false})<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>sb', [[<cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>sh', [[<cmd>lua require('telescope.builtin').help_tags()<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>sg', [[<cmd>lua require('telescope.builtin').live_grep()<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>sd', [[<cmd>lua require('telescope.builtin').grep_string()<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>?', [[<cmd>lua require('telescope.builtin').oldfiles()<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>sv', [[<cmd>lua require('telescope').setup { defaults = { layout_strategy = 'vertical', }, }<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>sz', [[<cmd>lua require('telescope').setup { defaults = { layout_strategy = 'horizontal', }, }<CR>]], opts)


-- Buffer Mappings
-- Close current buffer
vim.api.nvim_set_keymap('n', '<leader>bd', [[<cmd>bd<CR>]], opts)
-- Swap buffer
vim.api.nvim_set_keymap('n', '<leader>bs', [[<cmd>b#<CR>]], opts)
-- vim.api.nvim_set_keymap('n', '<leader><leader>', [[<cmd>b#<CR>]], opts)
-- Close current buffer and switch to last used
vim.api.nvim_set_keymap('n', '<leader>bq', [[<cmd>b#|bd#<CR>]], opts)

-- dap hotkeys
vim.api.nvim_set_keymap('n', '<leader>db', [[<cmd>lua require('dap').toggle_breakpoint()<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>dc', [[<cmd>lua require('dap').continue()<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>do', [[<cmd>lua require('dap').step_over()<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>di', [[<cmd>lua require('dap').step_into()<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>ds', [[<cmd>lua require('dap').close()<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>dro', [[<cmd>lua require('dap').repl.open()<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>drc', [[<cmd>lua require('dap').repl.close()<CR>]], opts)

-- quickfix hotkeys
vim.api.nvim_set_keymap('n', '<leader>qc', [[<cmd>cclose<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>qn', [[<cmd>cnext<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>qp', [[<cmd>cprev<CR>]], opts)

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
  autocmd BufNewFile,BufRead *.md setlocal wrap spell linebreak
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

" auto complete html closing tags
inoremap </ </<C-N>

"" Functions

" Setup cache directory so .swp files aren't in the cwd
if !isdirectory(expand("$HOME/.cache/nvim/swap"))
  call mkdir(expand("$HOME/.cache/nvim/swap"), "p")
endif
set directory=$HOME/.cache/nvim/swap

command! DiffOrig vertical new | set buftype=nofile | read # | 0d_ | diffthis | wincmd p | diffthis

"" Prettier
" Format on save (even without header)
let g:prettier#autoformat = 1
let g:prettier#autoformat_require_pragma = 0
nmap <Leader>pf <Plug>(PrettierAsync)

]],
  false
)

