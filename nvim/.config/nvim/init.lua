local plugins = require("plugins")
plugins.init() -- Install lazy if not exists and setup commands and autocmds

vim.g.mapleader = ','
vim.g.maplocalleader = ','

plugins.load() -- Load lazy with the spec

require('config.lang').setup()
require('config.debuggers').setup()

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
vim.opt.clipboard = 'unnamedplus' -- make the default yank register shared with + register
vim.opt.wrap = false
vim.opt.tabstop = indent
vim.opt.softtabstop = indent
vim.opt.shiftwidth = indent
vim.opt.expandtab = true -- converts tab presses to spaces
vim.opt.inccommand = 'nosplit' -- shows effects of substitutions
vim.opt.mouse = 'a' -- enable mouse usage
vim.opt.shortmess = "IF" -- disable the intro screen (display with `:intro`)
vim.opt.signcolumn = 'auto:1-3' -- make the sign column have between 1 and 3 elements
vim.opt.undofile = true --Save undo history
vim.opt.updatetime = 250 --Decrease update time
vim.opt.scrolloff = 6

-- experimental
vim.opt.jumpoptions = 'stack'

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
vim.keymap.set({ 'i', 'c' }, '<A-p>', '<C-r>+', opts)

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

-- Tabs
vim.keymap.set('n', '<leader>to', '<cmd>tabnew<cr><c-6>', opts)
vim.keymap.set('n', '<leader>tc', '<cmd>tabclose<cr>', opts)
vim.keymap.set('n', '<leader>tn', '<cmd>tabnext<cr>', opts)
vim.keymap.set('n', '<leader>tp', '<cmd>tabprevious<cr>', opts)


-- Edit vim config in split
vim.keymap.set('n', '<leader>ec', '<cmd>vsplit $MYVIMRC<cr>', opts)

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

local coding = require('coding')
vim.keymap.set({ 'n', 'v', 'o', 'i' }, '<A-f>', coding.print_function, opts)
vim.keymap.set({ 'n', 'v', 'o', 'i' }, '<A-c>', coding.print_class, opts)

local movement = require('movement')
vim.keymap.set('n', '}', movement.paragraph_down, opts)
vim.keymap.set('n', '{', movement.paragraph_up, opts)
vim.keymap.set('n', 'w', movement.forward_word, opts)
vim.keymap.set('n', 'b', movement.backward_word, opts)
vim.keymap.set('n', 'e', movement.forward_end_word, opts)

-- Stacktrace explorer
vim.keymap.set('n', '<leader>es', require('stacktraces').stacktrace_to_qflist)

-- Perforce open file picker
vim.keymap.set('n', '<leader>sp', require('perforce_picker').opened)


-- *** AUTOGROUPS *** --

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
  pattern = "*",
  -- callback = function() vim.highlight.on_yank() end,
  callback = function() vim.highlight.on_yank() end,
})

local group = vim.api.nvim_create_augroup("NumberToggle", { clear = true })
-- Turn on relativenumber for focused buffer
-- vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "InsertLeave" }, {
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "InsertLeave" }, {
  group = group,
  command = [[set relativenumber]]
})

-- Turn off relativenumber for unfocused buffers
-- vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "InsertEnter" }, {
vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave", "InsertEnter" }, {
  group = group,
  command = [[set norelativenumber]]
})

-- Various settings for markdown
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = vim.api.nvim_create_augroup("Markdown", { clear = true }),
  pattern = "*.md",
  command = [[setlocal wrap spell linebreak]]
})

-- Set the compiler to dotnet for cs files
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = vim.api.nvim_create_augroup("CSharp", { clear = true }),
  pattern = "*.cs",
  command = [[compiler dotnet]]
})

group = vim.api.nvim_create_augroup("ZigLang", { clear = true })
-- Set zig files to zig filetype
vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  pattern = "*.zig",
  command = [[set ft=zig]]
})

-- Abbreviate oom to error.OutOfMemory in Zig
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "zig",
  command = [[iabbrev <buffer> oom return error.OutOfMemory;]]
})

-- auto completion for html closing tags
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = vim.api.nvim_create_augroup("TagCompletion", { clear = true }),
  pattern = { "*.html", "*.xml" },
  callback = function() vim.keymap.set('i', '</', '</<c-n>', opts) end,
})

-- Set background colour for help
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("ReferenceColours", { clear = true }),
  pattern = { "help" },
  callback = function()
    vim.api.nvim_set_hl(55, "Normal", { bg = "#222730" })
    vim.api.nvim_win_set_hl_ns(0, 55)
  end,
})

-- Set indentation to 2 for lua and html
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("IndentTwo", { clear = true }),
  pattern = { "lua", "html" },
  command = [[setlocal shiftwidth=2 softtabstop=2 expandtab]]
})

-- Auto format Python, Lua and Rust files
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("AutoFormat", { clear = true }),
  pattern = { "*.rs", "*.py", "*.lua" },
  callback = function()
    -- We just want to autoformat but sometimes the lsp api call wipes
    -- out all signs and marks. Therefore, we cache and restore them
    -- Todo: just fix all signs and marks
    local sign_marks = require('signs')
    -- store sign_marks
    local placed_signs = sign_marks.get_all()

    -- actual autoformat (wipes signs and marks)
    vim.lsp.buf.format({ async = false })

    -- restore sign_marks
    sign_marks.set_all(placed_signs)
  end,
  -- Works, but errors are written to the buffer and cursor is moved
  -- callback = function() vim.cmd([[silent %!black -q --stdin-filename % -]]) end,
})

-- *** LUA *** --
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("LuaSpecific", { clear = true }),
  pattern = "*.lua",
  callback = function()
    -- create debugging print statement
    vim.keymap.set('n', '<leader>pd', require('print_debug').lua_print, opts)
  end
})

-- *** Python *** --
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("PythonSpecific", { clear = true }),
  pattern = "*.py",
  callback = function()
    -- organize imports with ruff
    vim.keymap.set('n', '<leader>fi', '<cmd>!ruff check --fix --select=I001 %:p<cr>', opts)
    -- start debugger
    vim.keymap.set('n', '<leader>ds',
      function()
        require('dap').attach(
          { type = "server", host = "127.0.0.1", port = 5678 },
          { type = "python", request = "attach", mode = "remote" }
        )
        require('dapui').open()
      end, opts)
    -- create debugging print statement
    vim.keymap.set('n', '<leader>pd', require('print_debug').python_print, opts)
    -- run ruff auto-fixer on the first error found on the current line
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
    -- run ruff explainer on the first error on the current line
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

-- *** Rust *** --
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("Cargo", { clear = true }),
  pattern = "rust",
  callback = function()
    -- setup cargo as the compiler
    vim.cmd([[compiler cargo]])
    vim.keymap.set('n', '<leader>bb', '<cmd>make build|cwindow<cr>', opts)
    vim.keymap.set('n', '<leader>bc', '<cmd>make clippy|cwindow<cr>', opts)
  end,
})

-- *** Rust (cont) *** --
-- TODO: should be FileType event?
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("RustSpecific", { clear = true }),
  pattern = "*.rs",
  callback = function()
    -- create debugging print statement
    vim.keymap.set('n', '<leader>pd', require('print_debug').print_rust, opts)
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
vim.keymap.set({ 'n' }, '<A-b>', require('buffers').close_unused_buffers, opts)

-- *** Setup Signs ***
local sign_marks = require('signs')
sign_marks.setup()
vim.keymap.set('n', 'mm', sign_marks.set_anchor)
vim.keymap.set('n', 'ms', sign_marks.set_start)
vim.keymap.set('n', 'me', sign_marks.set_end)

-- *** Setup Auto Marks ***

local index = 1
local letters = { 'W', 'X', 'Y', 'Z' }
local mark_count = 0
local curr_index = 0

local function set_mark()
  local letter = letters[index]
  index = index + 1
  if index > 4 then
    index = 1
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local lnum, cnum = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_mark(bufnr, letter, lnum, cnum, {})
  mark_count = math.min(mark_count + 1, 4)
end

vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*",
  callback = set_mark
})

local function previous_mark()
  if mark_count <= 1 then
    return
  end

  -- cycle down
  curr_index = curr_index - 1
  if curr_index < 1 then
    curr_index = mark_count
  end

  local letter = letters[curr_index]
  vim.cmd.normal("'" .. letter)
end

local function next_mark()
  if mark_count <= 1 then
    return
  end

  -- cycle up
  curr_index = curr_index + 1
  if curr_index > mark_count then
    curr_index = 1
  end

  local letter = letters[curr_index]
  print(letter)
  vim.cmd.normal("'" .. letter)
end

-- Note: there is also, jump to sign, so maybe don't need the marks
vim.keymap.set('n', '<leader>mp', previous_mark, opts)
vim.keymap.set('n', '<leader>mn', next_mark, opts)
vim.keymap.set('n', '<leader>ms', set_mark, opts)

-- replaces <c-f> <c-u> <c-b> <c-d> { } j k [* ]*
vim.keymap.set('n', '<c-e>', '10<C-e>')
vim.keymap.set('n', '<c-y>', '10<C-y>')

local indents = require('indents')
vim.keymap.set({ 'n', 'v' }, '<c-u>', indents.up_same_indent)
vim.keymap.set({ 'n', 'v' }, '<c-f>', indents.down_same_indent)
vim.keymap.set({ 'n', 'v' }, '<a-n>', indents.up_out_indent)
vim.keymap.set({ 'n', 'v' }, '<a-e>', indents.up_in_indent)
vim.keymap.set({ 'n', 'v' }, '<a-m>', indents.down_out_indent)
vim.keymap.set({ 'n', 'v' }, '<a-,>', indents.down_in_indent)

-- diag
vim.keymap.set('n', '<a-s>', indents.diag_up_out)
vim.keymap.set('n', '<a-t>', indents.diag_up_in)
vim.keymap.set('n', '<a-a>', indents.diag_down_out)
vim.keymap.set('n', '<a-r>', indents.diag_down_in)

-- could be moved: q, r, s, u, z, x, m


-- Todo: functions and classes? and methods?
-- Todo: make a hierarchy of functions, classes and methods (like the file tree plugin)
-- Todo: make lua impl
local function_picker = require('function_picker')
vim.keymap.set('n', '<leader>su', function_picker.functions)

-- Session management
local sessions = require('sessions')
sessions.initialize()

vim.keymap.set('n', '<leader>qq', '<cmd>qa<cr>')
vim.keymap.set('n', '<leader>qs', function()
  sessions.save_session()
  vim.cmd('qa')
end)

vim.keymap.set('n', '<leader>os', sessions.load_session)

local session_group = vim.api.nvim_create_augroup("SessionManagement", { clear = true })
-- Auto-save session
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = session_group,
  pattern = "*",
  callback = function() sessions.save_session() end,
})

-- Auto-load session
vim.api.nvim_create_autocmd("VimEnter", {
  group = session_group,
  pattern = "*",
  callback = function() sessions.load_session() end,
  nested = true
})
