local plugins = require("plugins")
plugins.init() -- Install lazy if not exists and setup commands and autocmds

vim.g.mapleader = ','
vim.g.maplocalleader = ','

plugins.load() -- Load lazy with the spec

require('config.lang').setup()
-- require('config.debuggers').setup()

-- *** CONFIG *** --

local indent = 4
local is_windows = vim.loop.os_uname().sysname == "Windows_NT"

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
vim.opt.clipboard = 'unnamedplus'
vim.opt.wrap = false

vim.opt.tabstop = indent
vim.opt.softtabstop = indent
vim.opt.shiftwidth = indent
vim.opt.expandtab = true -- converts tab presses to spaces
vim.opt.inccommand = 'nosplit' -- shows effects of substitutions
vim.opt.mouse = 'a'
vim.opt.shortmess = "IF" -- disable the intro screen (display with `:intro`)

--Save undo history
vim.opt.undofile = true

--Decrease update time
vim.opt.updatetime = 250
vim.opt.signcolumn = 'yes'

if is_windows then
  local win32yank = 'win32yank.exe'
  vim.g.clipboard = {
    name = "win32yank",
    copy = {
      ["+"] = { win32yank, '-i', '--crlf' },
      ["*"] = { win32yank, '-i', '--crlf' },
    },
    paste = {
      ["+"] = { win32yank, '-o', '--lf' },
      ["*"] = { win32yank, '-o', '--lf' },
    },
    cache_enabled = 1,
  }
else
  vim.g.clipboard = {
    name = "xsel",
    copy = {
      ["+"] = { 'xsel', '--nodetach', '-i', '-b' },
      ["*"] = { 'xsel', '--nodetach', '-i', '-p' },
    },
    paste = {
      ["+"] = { 'xsel', '-o', '-b' },
      ["*"] = { 'xsel', '-o', '-p' },
    },
    cache_enabled = 1,
  }
end

-- Setup auto compeletion
vim.o.completeopt = 'menu,menuone,noselect'

-- treat - seperated words as a word object
vim.api.nvim_exec([[ set iskeyword+=- ]], false)
-- treat _ seperated words as a word object
vim.api.nvim_exec([[ set iskeyword+=_ ]], false)

-- Add cute icons for the left margin
local signs = { Error = '', Warn = '', Hint = '', Info = '' }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

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

-- quick yank/paste
vim.keymap.set('n', '<leader>pp', 'ciw<C-r>0<Esc>', opts)
vim.keymap.set('n', '<leader>yy', 'yiw', opts)
vim.keymap.set('n', '<space>y', '"ty', opts)
vim.keymap.set('n', '<space>p', '"tP', opts)
vim.keymap.set('n', '<space>d', '"_d', opts)
vim.keymap.set('n', '<space>c', '"_c', opts)
vim.keymap.set('n', '<leader>ys', '"sy', opts)
vim.keymap.set('n', '<leader>ps', '"sP', opts)
-- vim.keymap.set('n', '<leader>ye', '"ey', opts)
-- vim.keymap.set('n', '<leader>pe', '"eP', opts)
vim.keymap.set('i', '<A-p>', '<C-r>"', opts)

-- map gp to re-select the thing you just pasted
vim.keymap.set('n', 'gp', '`[v`]', opts)

vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)

-- These use the <leader>l lsp prefix even though they aren't lsp specific.
vim.keymap.set('n', '<leader>le', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '<leader>lq', vim.diagnostic.setqflist, opts)

-- Generate test names in the standard format
-- vim.keymap.set("n", "<leader>tt", require('utils').transform_test_name, opts)

-- Buffer Mappings
-- Close current buffer
vim.keymap.set('n', '<leader>bd', '<cmd>bd<CR>', opts)
-- Swap buffer
vim.keymap.set('n', '<leader>,', '<cmd>b#<CR>', opts)
-- Close current buffer and switch to last used
vim.keymap.set('n', '<leader>bq', '<cmd>b#|bd#<CR>', opts)

-- Open Blender (this should be moved to a local file)
vim.keymap.set('n', '<leader>ob', '<cmd>!pwsh -nologo -c Start-Blender<CR><CR>', opts)

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
-- close the window below
vim.keymap.set('n', '<leader>dj', '<c-w>j<c-c>', opts)
-- close the window above
vim.keymap.set('n', '<leader>dk', '<c-w>k<c-c>', opts)

-- Edit vim config in split
vim.keymap.set('n', '<leader>ec', '<cmd>vsplit $MYVIMRC<cr>', opts)
-- Source vim config
vim.keymap.set('n', '<leader>sc', '<cmd>source $MYVIMRC<cr>', opts)

-- Remap keys in terminal mode
vim.keymap.set('t', '<esc>', '<c-\\><c-n>', opts)
vim.keymap.set('t', '<c-v><esc>', '<esc>', opts)

-- Nvim Tree
vim.keymap.set('n', '<c-n>', '<cmd>NvimTreeToggle<cr>', opts)
-- vim.keymap.set('n', '<leader>r', '<cmd>NvimTreeRefresh<cr>', opts)
vim.keymap.set('n', '<leader>st', '<cmd>NvimTreeFindFile<cr>', opts)

-- Run prettier
vim.keymap.set('n', '<leader>pf', '<cmd>PrettierAsync<cr>', opts)

-- Change or delete the word plus the first character after the word
vim.keymap.set('v', 'ew', 'vel', opts)
vim.keymap.set('o', 'ew', '<cmd>normal Vew<cr>')

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
  pattern = { "*.html", "*.xml" },
  callback = function() vim.keymap.set('i', '</', '</<c-n>', opts) end,
})

-- Set indentation to 2 for lua and html
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("IndentTwo", { clear = true }),
  pattern = { "lua", "html" },
  callback = function() vim.cmd([[setlocal shiftwidth=2 softtabstop=2 expandtab]]) end,
})

-- Auto format Python, Lua and Rust files
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("AutoFormat", { clear = true }),
  pattern = { "*.rs", ".py", "*.lua" },
  callback = function() vim.lsp.buf.format({ async = false }) end,
  -- Works, but errors are written to the buffer and cursor is moved
  -- callback = function() vim.cmd([[silent %!black -q --stdin-filename % -]]) end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("PythonSpecific", { clear = true }),
  pattern = "*.py",
  callback = function()
    vim.keymap.set('n', '<leader>fi', '<cmd>!ruff check --fix --select=I001 %:p<cr>', opts)
    -- vim.keymap.set('n', '<leader>pd', 'yiwoprint(f""(<cmd>lua vim.api.nvim_win_get_cursor(0)<cr>i): {"}")', opts)
    vim.keymap.set('n', '<leader>pd',
      function()
        vim.cmd.normal('yiwoprint(f"" ')
        local pos = vim.api.nvim_win_get_cursor(0)
        vim.cmd.normal('a: {"}")')
        vim.api.nvim_buf_set_text(0, pos[1] - 1, pos[2] + 1, pos[1] - 1, pos[2] + 1, { '(' .. tostring(pos[1]) .. ')' })
      end, opts)
    vim.keymap.set('n', '<leader>pf',
      function()
        local lnum, _ = unpack(vim.api.nvim_win_get_cursor(0))
        local errors = vim.diagnostic.get(0, { lnum = lnum - 1 })
        for _, err in pairs(errors) do
          if err.source == "ruff" then
            vim.cmd('!ruff check --fix --select=' .. err.code .. ' %:p')
            -- only fix the first error
            -- TODO: print a menu and let me decide which error to fix
            break
          end
        end
      end, opts)
    vim.keymap.set('n', '<leader>pe',
      function()
        local lnum, _ = unpack(vim.api.nvim_win_get_cursor(0))
        local errors = vim.diagnostic.get(0, { lnum = lnum - 1 })
        for _, err in pairs(errors) do
          if err.source == "ruff" then
            vim.cmd('!ruff rule ' .. err.code)
          end
        end
      end, opts)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("Cargo", { clear = true }),
  pattern = "rust",
  callback = function()
    vim.cmd([[compiler cargo]])
    vim.keymap.set('n', '<leader>bb', '<cmd>make build|copen<cr>', opts)
  end,
})

-- TODO: should be FileType event?
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("RustSpecific", { clear = true }),
  pattern = "*.rs",
  callback = function()
    vim.keymap.set('n', '<leader>pd',
      function()
        vim.cmd.normal('yiwoprintln!("" ')
        local pos = vim.api.nvim_win_get_cursor(0)
        vim.cmd.normal('a: {}", ");')
        vim.api.nvim_buf_set_text(0, pos[1] - 1, pos[2] + 1, pos[1] - 1, pos[2] + 1, { '(' .. tostring(pos[1]) .. ')' })
      end, opts)
  end,
})

-- Hide exit code on terminal close
vim.api.nvim_create_autocmd("TermClose", {
  pattern = "*",
  callback = function() vim.cmd([[if !v:event.status | exe 'bdelete! '..expand('<abuf>') | endif]]) end,
})

-- *** MISCELLANEOUS *** --

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
vim.api.nvim_create_user_command('DiffOrig', function()
  vim.cmd([[vertical new | set buftype=nofile | read # | 0d_ | diffthis | wincmd p | diffthis ]])
end, {})

-- redirect command output to a buffer
vim.api.nvim_create_user_command('Redir', function(ctx)
  local lines = vim.split(vim.api.nvim_exec(ctx.args, true), '\n', { plain = true })
  vim.cmd('enew')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.opt_local.modified = false
end, { nargs = '+', complete = 'command' })


-- Give the name of the current class or function
local function find_parent_node(node, node_type)
  while node do
    if node:type() == node_type then
      break
    end
    node = node:parent()
  end
  return node
end

local function get_node_by_type(node_type)
  local ts_utils = require('nvim-treesitter.ts_utils')
  local node = ts_utils.get_node_at_cursor()
  return find_parent_node(node, node_type)
end

local function get_first_line_of_node_text(node, bufnr)
  if not node then return "" end
  local node_text = vim.treesitter.get_node_text(node, bufnr)
  return node_text:match("([^\n]*)\n?")
end

local function print_function()
  local node = get_node_by_type('function_definition')
  if not node then
    node = get_node_by_type('function_declaration')
  end
  local line = get_first_line_of_node_text(node, 0)
  print(line)
end

local function print_class()
  local node = get_node_by_type('class_definition')
  local line = get_first_line_of_node_text(node, 0)
  print(line)
end

vim.keymap.set({ 'n', 'v', 'o', 'i' }, '<A-f>', print_function, opts)
vim.keymap.set({ 'n', 'v', 'o', 'i' }, '<A-c>', print_class, opts)


local function get_win_filename(winnr)
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  return vim.api.nvim_buf_get_name(bufnr)
end

local function print_win_filenames()
  local windows = vim.api.nvim_list_wins()
  for _, window in pairs(windows) do
    local buf_name = get_win_filename(window)
    print(buf_name)
  end
end

vim.keymap.set({ 'n' }, '<A-w>', print_win_filenames, opts)

local function print_bufs()
  local keep = {}
  local windows = vim.api.nvim_list_wins()
  for _, window in pairs(windows) do
    local buf = vim.api.nvim_win_get_buf(window)
    -- local buf_name = get_win_filename(window)
    table.insert(keep, buf)
  end

  local bufs = vim.api.nvim_list_bufs()
  for _, buf in pairs(bufs) do
    local found = false
    for _, k in pairs(keep) do
      if buf == k then
        found = true
      end
    end
    if not found then
      vim.api.nvim_buf_delete(buf, {})
    end
  end
end

vim.keymap.set({ 'n' }, '<A-b>', print_bufs, opts)
