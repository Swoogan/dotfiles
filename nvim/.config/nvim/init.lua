local plugins = require("plugins")
plugins.init() -- Install packer if not exists and setup commands and autocmds
plugins.load() -- Load packer with the packer spec

require('config.plugins').setup()
require('config.lang').setup()
-- require('config.debuggers').setup()
require('config.snippets').setup()

-- *** CONFIG *** --

local indent = 4

-- Vim options
vim.opt.termguicolors = true
vim.opt.number = true -- show the current line number (w/ relative on)
vim.opt.relativenumber = true -- show relative line numbers
vim.opt.splitbelow = true -- new horizontal windows appear on the bottom
vim.opt.splitright = true -- new vertical windows appear on the right
vim.opt.smartindent = true
vim.opt.cursorline = true -- highlights current line
vim.opt.smartcase = true -- searching case insensitive unless mixed case
vim.opt.ignorecase = true
vim.opt.wrap = false

vim.opt.tabstop = indent
vim.opt.softtabstop = indent
vim.opt.shiftwidth = indent
vim.opt.expandtab = true -- converts tab presses to spaces
vim.opt.inccommand = 'nosplit' -- shows effects of substitutions
vim.opt.mouse = 'a'

--Save undo history
vim.opt.undofile = true

--Decrease update time
vim.opt.updatetime = 250
vim.opt.signcolumn = 'yes'

vim.g.mapleader = ','
vim.g.maplocalleader = ','

-- disable builtin plugins I don't use
vim.g.loaded_tutor = 1
vim.g.loaded_netrwPlugin = 1

-- Setup auto compeletion
vim.o.completeopt = "menu,menuone,noselect"

-- treat - seperated words as a word object
vim.api.nvim_exec([[ set iskeyword+=- ]], false)
-- treat _ seperated words as a word object
vim.api.nvim_exec([[ set iskeyword+=_ ]], false)

-- *** THEME *** --

require('nightfox').setup({
  options = {
    styles = {
        comments = "italic"
    }
  }
})

vim.cmd("colorscheme nightfox")

-- *** MAPPINGS *** --

-- Note: some mappings are in the lua/config/*.lua modules

local opts = { noremap = true, silent = true }

-- not sure why I do this?
vim.keymap.set('', '<Space>', '<Nop>', opts)

-- map gp to re-select the thing you just pasted
vim.keymap.set('n', 'gp', '`[v`]', opts)

vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)

-- These use the <leader>l lsp prefix even though they aren't lsp specific.
vim.keymap.set('n', '<leader>le', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '<leader>lq', vim.diagnostic.setloclist, opts)

-- Generate test names in the standard format
vim.keymap.set("n", "<leader>tt", require('utils').transform_test_name, opts)

-- Add telescope shortcuts
vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, opts)
vim.keymap.set('n', '<leader>sf', function() require('telescope.builtin').find_files({ previewer = false }) end, opts)
vim.keymap.set('n', '<leader>sb', require('telescope.builtin').current_buffer_fuzzy_find, opts)
vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, opts)
vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep, opts)
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').grep_string, opts)
vim.keymap.set('n', '<leader>so', require('telescope.builtin').oldfiles, opts)
vim.keymap.set('n', '<leader>sv',
    function() require('telescope').setup { defaults = { layout_strategy = 'vertical', }, } end, opts)
vim.keymap.set('n', '<leader>sz',
    function() require('telescope').setup { defaults = { layout_strategy = 'horizontal', }, } end, opts)

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)

-- Buffer Mappings
-- Close current buffer
vim.keymap.set('n', '<leader>bd', '<cmd>bd<CR>', opts)
-- lua vim.api.nvim_buf_delete(vim.api.nvim_get_current_buf(), {})
-- Swap buffer
vim.keymap.set('n', '<leader>bd', '<cmd>bd<CR>', opts)
-- vim.api.nvim_set_keymap('n', '<leader><leader>', [[<cmd>b#<CR>]], opts)
-- Close current buffer and switch to last used
vim.keymap.set('n', '<leader>bq', '<cmd>b#|bd#<CR>', opts)

-- dap hotkeys
-- local dap = require('dap')
-- vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, opts)
-- vim.keymap.set('n', '<leader>dc', dap.continue, opts)
-- vim.keymap.set('n', '<leader>do', dap.step_over, opts)
-- vim.keymap.set('n', '<leader>di', dap.step_into, opts)
-- vim.keymap.set('n', '<leader>ds', dap.close, opts)
-- vim.keymap.set('n', '<leader>dro', dap.repl.open, opts)
-- vim.keymap.set('n', '<leader>drc', dap.repl.close, opts)

-- quickfix hotkeys
vim.keymap.set('n', '<leader>qc', '<cmd>cclose<CR>', opts)
vim.keymap.set('n', '<leader>qn', '<cmd>cnext<CR>', opts)
vim.keymap.set('n', '<leader>qp', '<cmd>cprev<CR>', opts)

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

-- Run prettier
vim.keymap.set('n', '<leader>pf', '<cmd>PrettierAsync<cr>', opts)

-- *** AUTOGROUPS *** --

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
    pattern = "*", -- silent!
    callback = function() vim.highlight.on_yank() end,
})

local group = vim.api.nvim_create_augroup("NumberToggle", { clear = true })
-- Turn on relativenumber for focused buffer
vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "InsertLeave" }, {
    group = group,
    pattern = "*",
    callback = function() vim.cmd([[set relativenumber]]) end,
})

-- Turn off relativenumber for unfocused buffers
vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "InsertEnter" }, {
    group = group,
    pattern = "*",
    callback = function() vim.cmd([[set norelativenumber]]) end,
})

-- Various settings for markdown
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
    group = vim.api.nvim_create_augroup("Markdown", { clear = true }),
    pattern = "*.md",
    callback = function() vim.cmd([[setlocal wrap spell linebreak]]) end,
})

-- Set the compiler to dotnet for cs files
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
    group = vim.api.nvim_create_augroup("CSharp", { clear = true }),
    pattern = "*.cs",
    callback = function() vim.cmd([[compiler dotnet]]) end,
})

group = vim.api.nvim_create_augroup("ZigLang", { clear = true })
-- Set zig files to zig filetype
vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    pattern = "*.zig",
    callback = function() vim.cmd([[set ft=zig]]) end,
})

-- Abbreviate oom to error.OutOfMemory in Zig
vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "zig",
    callback = function() vim.cmd([[iabbrev <buffer> oom return error.OutOfMemory;]]) end,
})

-- auto completion for html closing tags
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = vim.api.nvim_create_augroup("TagCompletion", { clear = true }),
  pattern = {"*.html", "*.xml"},
  callback = function() vim.keymap.set('i', '</', '</<c-n>', opts) end,
})

-- Set indentation to 2 for lua and html
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("IndentTwo", { clear = true }),
    pattern = { "lua", "html" },
    callback = function() vim.cmd([[setlocal shiftwidth=2 softtabstop=2 expandtab]]) end,
})

vim.api.nvim_create_autocmd("TermClose", {
    pattern = "*",
    callback = function() vim.cmd([[if !v:event.status | exe 'bdelete! '..expand('<abuf>') | endif]]) end,
})

-- *** MISCELLANEOUS *** --

local is_windows = vim.loop.os_uname().sysname == "Windows_NT"

-- launch a terminal
if is_windows then
    vim.keymap.set('n', '<leader>t', '<cmd>10split|term pwsh -NoLogo<Cr>a', opts)
else
    vim.keymap.set('n', '<leader>t', '<cmd>10split|term<Cr>a', opts)
end

-- set swap folder
local swap = vim.fn.expand("$HOME/.cache/nvim/swap")
if not vim.fn.isdirectory(swap) then
    vim.fn.mkdir(swap, "p")
end
vim.cmd([[set directory=$HOME/.cache/nvim/swap]])

-- diff a file against the unchanged state
vim.api.nvim_create_user_command("DiffOrig", function()
    vim.cmd([[vertical new | set buftype=nofile | read # | 0d_ | diffthis | wincmd p | diffthis ]])
end, {})
