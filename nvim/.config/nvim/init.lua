local plugins = require("plugins")
plugins.init() -- Install packer if not exists and setup commands and autocmds
plugins.load() -- Load packer with the packer spec

local cmd = vim.cmd
local indent = 4
local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
local opts = { noremap=true, silent=true }

vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)

-- Setup Language sever protocol
local nvim_lsp = require('lspconfig')

local on_attach = function(client, bufnr)
  --Enable completion triggered by <c-x><c-o>
   vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)

  -- vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  -- vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  -- vim.keymap.set('n', '<space>wl', function()
  --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  -- end, bufopts)

  -- TODO: unify these keypresses
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', '<leader>sh', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', '<leader>f', vim.lsp.buf.formatting, bufopts)
  vim.keymap.set('n', '<leader>so', require('telescope.builtin').lsp_document_symbols, bufopts)

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
  }
end

-- Setup PowerShell Editor Extensions
local bundle_path = vim.env.DEV_HOME .. '/.ls/PowerShellEditorServices'

nvim_lsp['powershell_es'].setup {
  bundle_path = bundle_path,
  -- pwsh, the default, does not work for some reason
  shell = 'powershell.exe',
  capabilities = capabilities,
  on_attach = on_attach,
}

-- Setup OmniSharp
local pid = vim.fn.getpid()
local omnisharp = vim.env.DEV_HOME .. '/.ls/omnisharp/OmniSharp.exe'

nvim_lsp['omnisharp'].setup {
  handlers = {
    ["textDocument/definition"] = require('omnisharp_extended').handler,
  },
  capabilities = capabilities,
  on_attach = on_attach,
  cmd = { omnisharp, "--languageserver" , "--hostPID", tostring(pid), "formattingOptions:EnableEditorConfigSupport=true" }
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
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }),
    sources = cmp.config.sources({
	    { name = 'nvim_lsp' },
	    { name = 'luasnip' },
    }, {
	    { name = 'buffer' },
    }),
    completion = { keyword_length = 3 }
})


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
vim.keymap.set("n", "<leader>tt", transform_test_name, opts)

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
vim.opt.undofile = true

--Decrease update time
vim.opt.updatetime = 250
vim.opt.signcolumn = 'yes'

vim.keymap.set('', '<Space>', '<Nop>', opts)
vim.g.mapleader = ','
vim.g.maplocalleader = ','

vim.g.loaded_tutor = 1
vim.g.loaded_netrwPlugin = 1



-- Add telescope shortcuts
vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, opts)
-- vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files({previewer = false}), opts)
vim.keymap.set('n', '<leader>sb', require('telescope.builtin').current_buffer_fuzzy_find, opts)
vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, opts)
vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep, opts)
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').grep_string, opts)
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, opts)
-- vim.keymap.set('n', '<leader>sv', require('telescope').setup { defaults = { layout_strategy = 'vertical', }, }, opts)
-- vim.keymap.set('n', '<leader>sz', require('telescope').setup { defaults = { layout_strategy = 'horizontal', }, }, opts)

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)

-- Buffer Mappings
-- Close current buffer
vim.api.nvim_set_keymap('n', '<leader>bd', [[<cmd>bd<CR>]], opts)
-- lua vim.api.nvim_buf_delete(vim.api.nvim_get_current_buf(), {})
-- Swap buffer
vim.api.nvim_set_keymap('n', '<leader>bs', [[<cmd>b#<CR>]], opts)
-- vim.api.nvim_set_keymap('n', '<leader><leader>', [[<cmd>b#<CR>]], opts)
-- Close current buffer and switch to last used
vim.api.nvim_set_keymap('n', '<leader>bq', [[<cmd>b#|bd#<CR>]], opts)

-- dap hotkeys
vim.keymap.set('n', '<leader>db', require('dap').toggle_breakpoint, opts)
vim.keymap.set('n', '<leader>dc', require('dap').continue, opts)
vim.keymap.set('n', '<leader>do', require('dap').step_over, opts)
vim.keymap.set('n', '<leader>di', require('dap').step_into, opts)
vim.keymap.set('n', '<leader>ds', require('dap').close, opts)
vim.keymap.set('n', '<leader>dro', require('dap').repl.open, opts)
vim.keymap.set('n', '<leader>drc', require('dap').repl.close, opts)

-- quickfix hotkeys
vim.api.nvim_set_keymap('n', '<leader>qc', [[<cmd>cclose<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>qn', [[<cmd>cnext<CR>]], opts)
vim.api.nvim_set_keymap('n', '<leader>qp', [[<cmd>cprev<CR>]], opts)

-- treat - seperated words as a word object
vim.api.nvim_exec([[ set iskeyword+=- ]], false)
-- treat _ seperated words as a word object  
vim.api.nvim_exec([[ set iskeyword+=_ ]], false)

-- launch a terminal
if is_windows then
    vim.api.nvim_set_keymap('n', '<leader>t', [[<cmd>10split\|term pwsh<Cr>a<CR>]], opts)
else
    vim.api.nvim_set_keymap('n', '<leader>qp', [[<cmd>10split\|term<Cr>a<CR>]], opts)
end

-- autogroups

-- -- Highlight on yank
id = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  group = id,
  pattern = "*", -- silent! 
  callback = function() vim.highlight.on_yank() end,
})

id = vim.api.nvim_create_augroup("NumberToggle", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "InsertLeave" }, {
  group = id,
  pattern = "*",
  callback = function() vim.cmd([[set relativenumber]]) end,
})

vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "InsertEnter" }, {
  group = id,
  pattern = "*",
  callback = function() vim.cmd([[set norelativenumber]]) end,
})

id = vim.api.nvim_create_augroup("Markdown", { clear = true })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = id,
  pattern = "*.md",
  callback = function() vim.cmd([[setlocal wrap spell linebreak]]) end,
})

id = vim.api.nvim_create_augroup("CSharp", { clear = true })
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = id,
  pattern = "*.cs",
  callback = function() vim.cmd([[compiler dotnet]]) end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = id,
  pattern = "*.zig",
  callback = function() vim.cmd([[set ft=zig]]) end,
})

id = vim.api.nvim_create_augroup("ZigLang", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = id,
  pattern = "zig",
  callback = function() vim.cmd([[iabbrev <buffer> oom return error.OutOfMemory;]]) end,
})

---- Mappings
-- Repeats the character under the cursor
vim.keymap.set('n', '<leader>r', 'ylp', opts)

-- Removes search highlighting
vim.keymap.set('n', '<leader>nl', '<cmd>nohl<cr>', opts)
-- Save file
vim.keymap.set('n', '<leader>w', '<esc><cmd>w<cr>', opts)
-- Save and quit
vim.keymap.set('n', '<leader>x', '<esc><cmd>x<cr>', opts)

-- Simplified window management
vim.keymap.set('n', '<c-h>', '<c-w>h', opts)
vim.keymap.set('n', '<c-j>', '<c-w>j', opts)
vim.keymap.set('n', '<c-k>', '<c-w>k', opts)
vim.keymap.set('n', '<c-l>', '<c-w>l', opts)

-- Yanks selection to system clipboard
vim.keymap.set('n', '<leader>y', '"+y', opts)
-- Yanks selection to system clipboard
vim.keymap.set('v', '<leader>y', '"+y', opts)
-- Yanks line to system clipboard
vim.keymap.set('n', '<leader>yy', '"+yy', opts)
-- Pastes from system clipboard
vim.keymap.set('n', '<leader>p', '"+p', opts)
-- Pastes from system clipboard
vim.keymap.set('n', '<leader>P', '"+P', opts)

-- Edit vim config in split
vim.keymap.set('n', '<leader>ec', '<cmd>vsplit $MYVIMRC<cr>', opts)
-- Source vim config
vim.keymap.set('n', '<leader>sc', '<cmd>source $MYVIMRC<cr>', opts)

-- Remap keys in terminal mode
vim.keymap.set('t', '<esc>', '<c-\\><c-n>', opts)
vim.keymap.set('t', '<c-v><esc>', '<esc>', opts)

vim.keymap.set('n', '<c-n>', '<cmd>NvimTreeToggle<cr>', opts)
-- vim.keymap.set('n', '<leader>r', '<cmd>NvimTreeRefresh<cr>', opts)
-- vim.keymap.set('n', '<leader>n', '<cmd>NvimTreeFindFile<cr>', opts)

-- auto complete html closing tags
-- vim.keymap.set('i', '</', '</<c-n>', opts)
vim.api.nvim_exec([[inoremap </ </<C-N>]], false)

-- Add: Press sa{motion/textobject}{addition}. For example, a key sequence saiw( makes foo to (foo).
-- Delete: Press sdb or sd{deletion}. For example, key sequences sdb or sd( makes (foo) to foo. sdb searches a set of surrounding automatically.
-- Replace: Press srb{addition} or sr{deletion}{addition}. For example, key sequences srb" or sr(" makes (foo) to "foo".
vim.api.nvim_exec( [[ let g:sandwich#recipes = deepcopy(g:sandwich#default_recipes) ]], false)

-- local function is_dir(filename)
--   local stat = vim.loop.fs_stat(filename)
--   return stat and stat.type == 'directory' or false
-- end

local swap = vim.fn.expand("$HOME/.cache/nvim/swap")
if not vim.fn.isdirectory(swap) then
  vim.fn.mkdir(swap, "p")
end
vim.cmd([[set directory=$HOME/.cache/nvim/swap]])

vim.api.nvim_create_user_command("DiffOrig", function()
  vim.cmd([[vertical new | set buftype=nofile | read # | 0d_ | diffthis | wincmd p | diffthis ]])
end, {})

-- Prettier
vim.g['prettier#autoformat'] = 1
vim.g['prettier#autoformat_require_pragma'] = 0
vim.keymap.set('n', '<leader>pf', '<cmd>PrettierAsync<cr>', opts)
