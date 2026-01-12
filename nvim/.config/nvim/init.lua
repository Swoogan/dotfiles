local plugins = require("plugins")
plugins.init() -- Install lazy if not exists and setup commands and autocmds

vim.g.mapleader = ','
vim.g.maplocalleader = ','

plugins.load() -- Load lazy with the spec

require('config.lang').setup()
require('reference_win').setup()

-- local local_config = require('local_config')
-- local config           = local_config.load_config() or { location = "global" }

-- *** CONFIG *** --

local indent           = 4
local is_windows       = require('utils').is_windows()

-- Vim options
vim.opt.number         = true          -- show the current line number (w/ relative on)
vim.opt.splitbelow     = true          -- new horizontal windows appear on the bottom
vim.opt.splitright     = true          -- new vertical windows appear on the right
vim.opt.smartindent    = true
vim.opt.cursorline     = true          -- highlights current line
vim.opt.smartcase      = true          -- searching case insensitive unless mixed case
vim.opt.ignorecase     = true
vim.opt.clipboard      = 'unnamedplus' -- make the default yank register shared with + register
vim.opt.wrap           = false
vim.opt.tabstop        = indent
vim.opt.softtabstop    = indent
vim.opt.shiftwidth     = indent
vim.opt.expandtab      = true       -- converts tab presses to spaces
vim.opt.inccommand     = 'nosplit'  -- shows effects of substitutions
vim.opt.mouse          = 'a'        -- enable mouse usage
vim.opt.shortmess      = "IF"       -- disable the intro screen (display with `:intro`)
vim.opt.signcolumn     = 'auto:1-3' -- make the sign column have between 1 and 3 elements
vim.opt.undofile       = true       --Save undo history
vim.opt.updatetime     = 250        --Decrease update time
vim.opt.scrolloff      = 6
vim.opt.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,terminal"
vim.opt.shada          = "'100,f1,<50,:100,/100,h"

-- Use pwsh as "shell"
if is_windows then
  vim.opt.shell        = 'pwsh'
  vim.opt.shellcmdflag =
  '-NoLogo -NonInteractive -Command $PSStyle.OutputRendering = [System.Management.Automation.OutputRendering]::PlainText;'
  vim.opt.shellredir   = '2>&1 | %%{ "$_" } | Out-File %s; exit $LastExitCode'
  vim.opt.shellpipe    = '2>&1 | %%{ "$_" } | Tee-Object %s; exit $LastExitCode'
  vim.opt.shellquote   = ''
  vim.opt.shellxquote  = ''
end


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
vim.cmd([[ set iskeyword+=- ]])
-- treat _ seperated words as a word object
vim.cmd([[ set iskeyword+=_ ]])

-- Add cute icons for the left margin
vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN] = '',
      [vim.diagnostic.severity.INFO] = '',
      [vim.diagnostic.severity.HINT] = '',
    }
  }
})
-- end

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

-- Add machine specific keymaps
require('local_config').keymaps()

-- Note: some mappings are in the lua/config/*.lua modules

local opts = { noremap = true, silent = true }

-- not sure why I do this?
vim.keymap.set('', '<Space>', '<Nop>', opts)

-- quick yank/paste
vim.keymap.set('n', '<leader>pp', 'ciw<C-r>0<Esc>', opts)
vim.keymap.set('n', '<leader>yy', 'yiw', opts)
vim.keymap.set('n', '<space>d', '"_d', opts)
vim.keymap.set('n', '<space>c', '"_c', opts)
vim.keymap.set({ 'i' }, '<A-p>', '<C-r>+', opts)
vim.keymap.set({ 'c' }, '<A-p>', '<cmd>iput<cr>', opts)

-- map gp to re-select the thing you just pasted
vim.keymap.set('n', 'gp', '`[v`]', opts)

vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)

-- These use the <leader>l lsp prefix even though they aren't lsp specific.
vim.keymap.set('n', '<leader>le', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '<leader>lq', vim.diagnostic.setqflist, opts)

-- Buffer Mappings
-- Close current buffer
vim.keymap.set('n', '<leader>bd', '<cmd>bd<CR>', opts)
-- Swap buffer
vim.keymap.set('n', '<leader>,', '<cmd>b#<CR>', opts)
-- Close current buffer and switch to last used
vim.keymap.set('n', '<leader>bq', '<cmd>b#|bd#<CR>', opts)

-- quickfix hotkeys
vim.keymap.set('n', '<leader>qc', '<cmd>cclose<CR>', opts)
vim.keymap.set('n', '<leader>qn', '<cmd>cnext<CR>', opts)
vim.keymap.set('n', '<leader>qp', '<cmd>cprev<CR>', opts)

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
vim.keymap.set('n', '<leader>to', function()
  local lnum, cnum = unpack(vim.api.nvim_win_get_cursor(0))
  vim.cmd('tabnew %')
  vim.api.nvim_win_set_cursor(0, { lnum, cnum })
end, opts)
vim.keymap.set('n', '<leader>tc', '<cmd>tabclose<cr>', opts)
vim.keymap.set('n', '<leader>tn', '<cmd>tabnext<cr>', opts)
vim.keymap.set('n', '<leader>tp', '<cmd>tabprevious<cr>', opts)

-- Close build output
vim.keymap.set('n', '<leader>co', require('cpp').close_build_output, opts)

-- Nvim Tree
vim.keymap.set('n', '<c-n>', '<cmd>NvimTreeToggle<cr>', opts)
vim.keymap.set('n', '<leader>st', '<cmd>NvimTreeFindFile<cr>', opts)

-- Run prettier
vim.keymap.set('n', '<leader>pf', '<cmd>PrettierAsync<cr>', opts)

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
vim.keymap.set('n', '<leader>es', require('stacktraces').stacktrace_to_qflist, opts)

-- Perforce file pickers
vim.keymap.set('n', '<leader>sp', require('perforce_picker').opened, opts)
-- vim.keymap.set('n', '<leader>sa', require('perforce_picker').changelists, opts)
vim.keymap.set("n", "<leader>si", require('perforce_picker').diff_locations, opts)

-- Clean (convert) paths
vim.keymap.set('v', '<leader>ap', function()
  vim.cmd.normal(vim.keycode("<Esc>")) -- Need to do this so the visual marks are set
  vim.cmd([[silent! '<,'>s;\\\\;\\;g]])
  vim.cmd([[silent! '<,'>s;\\;/;g]])
  -- set the cursor back to where we started the visual mark
  local pos = vim.api.nvim_buf_get_mark(0, "<")
  vim.api.nvim_win_set_cursor(0, pos)
end, opts)

-- *** AUTOGROUPS *** --

-- Set jump marks when buffer is modified (lol this already exists in `changelist`)
-- vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
--   group = vim.api.nvim_create_augroup("TextChanged", { clear = true }),
--   pattern = "*",
--   callback = function() require('jumps').set_jump() end,
-- })
-- vim.keymap.set({ 'n', 'v' }, '<c-o>', require('jumps').jump_back, opts)
-- vim.keymap.set({ 'n', 'v' }, '<c-i>', require('jumps').jump_forward, opts)

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
  pattern = "*",
  callback = function() vim.highlight.on_yank() end,
})

-- Various settings for markdown
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = vim.api.nvim_create_augroup("Markdown", { clear = true }),
  pattern = "*.md",
  command = [[setlocal wrap spell linebreak]]
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = vim.api.nvim_create_augroup("CppSpecific", { clear = true }),
  pattern = { "*.cpp", "*.h" },
  callback = function()
    vim.cmd([[set indentexpr=]])
    -- don't want pointers to be part of a word
    vim.cmd([[ set iskeyword-=- ]])
  end
})

-- Set the compiler to dotnet for cs files
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = vim.api.nvim_create_augroup("C#Specific", { clear = true }),
  pattern = "*.cs",
  command = [[compiler dotnet]]
})

local ziggroup = vim.api.nvim_create_augroup("ZigSpecific", { clear = true })
-- Set zig files to zig filetype (todo: see if this is still needed)
vim.api.nvim_create_autocmd("BufReadPost", {
  group = ziggroup,
  pattern = "*.zig",
  command = [[set ft=zig]]
})

-- Abbreviate oom to error.OutOfMemory in Zig
vim.api.nvim_create_autocmd("FileType", {
  group = ziggroup,
  pattern = "zig",
  command = [[iabbrev <buffer> oom return error.OutOfMemory;]]
})

-- restore cursor position when re-opening a file
vim.api.nvim_create_autocmd('BufRead', {
  callback = function(lopts)
    vim.api.nvim_create_autocmd('BufWinEnter', {
      once = true,
      buffer = lopts.buf,
      callback = function()
        local ft = vim.bo[lopts.buf].filetype
        local last_known_line = vim.api.nvim_buf_get_mark(lopts.buf, '"')[1]
        if
            not (ft:match('commit') and ft:match('rebase'))
            and last_known_line > 1
            and last_known_line <= vim.api.nvim_buf_line_count(lopts.buf)
        then
          vim.api.nvim_feedkeys([[g`"]], 'nx', false)
        end
      end,
    })
  end,
})

-- Set background colour for help
local reference_colours = vim.api.nvim_create_augroup("ReferenceColours", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = reference_colours,
  pattern = { "help" },
  callback = function()
    vim.api.nvim_win_set_hl_ns(0, require('reference_win').namespace_id)
  end,
})

-- Clear reference window background colour on insert
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  group = reference_colours,
  callback = function()
    local winnr = vim.api.nvim_get_current_win()
    if require('reference_win').is_references_win(winnr) then
      require('reference_win').clear_reference_state(winnr)
    end
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

    -- local bufnr = vim.api.nvim_win_get_buf(0)
    -- local old_location = vim.api.nvim_win_get_cursor(0)

    -- actual autoformat (wipes signs and marks)
    vim.lsp.buf.format({ async = false })

    -- local windows = vim.api.nvim_list_wins()
    --
    -- for _, win in ipairs(windows) do
    --   if vim.api.nvim_win_get_buf(win) == bufnr then
    --     -- why pcall?
    --     -- pcall(vim.api.nvim_win_set_cursor, win, old_location)
    --     vim.api.nvim_win_set_cursor(win, old_location)
    --   end
    -- end

    -- restore sign_marks
    sign_marks.set_all(placed_signs)
  end,
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

-- *** PowerShell *** --
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("PwshSpecific", { clear = true }),
  pattern = { "*.ps1", "*.psm1" },
  callback = function()
    -- create debugging print statement
    vim.keymap.set('n', '<leader>pd', require('print_debug').print_pwsh, opts)
    vim.cmd([[ set iskeyword+=$ ]])
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
          if string.lower(err.source) == "ruff" then
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
    vim.keymap.set('n', '<leader>bb', require('rust_mono').build, opts)
    vim.keymap.set('n', '<leader>br', require('rust_mono').run, opts)
    vim.keymap.set('n', '<leader>bc', require('rust_mono').clippy, opts)

    -- create debugging print statement
    vim.keymap.set('n', '<leader>pd', require('print_debug').print_rust, opts)
  end,
})

-- *** Terminal ***
-- launch a terminal
vim.keymap.set('n', '<leader>te', '<cmd>10split|term<Cr>a', opts)

-- Hide exit code on terminal close
if is_windows then
  vim.api.nvim_create_autocmd('TermClose', {
    pattern = '*',
    callback = function()
      vim.schedule(function()
        if vim.bo.buftype == 'terminal' and vim.v.shell_error == 0 then
          vim.cmd('bdelete! ' .. vim.fn.expand('<abuf>'))
        end
      end)
    end,
  })
end

-- Remap keys in terminal mode
vim.keymap.set('t', '<esc>', '<c-\\><c-n>', opts)
vim.keymap.set('t', '<c-v><esc>', '<esc>', opts)


-- *** MISCELLANEOUS *** --

-- diff a file against the unchanged state
vim.api.nvim_create_user_command('DiffOrig', function()
  vim.cmd([[vertical new | set buftype=nofile | read # | 0d_ | diffthis | wincmd p | diffthis ]])
end, {})

-- redirect command output to a buffer
vim.api.nvim_create_user_command('Redir', function(ctx)
  local result = vim.api.nvim_exec2(ctx.args, { output = true })
  local lines = vim.split(result.output, '\r?\n')
  vim.cmd('enew')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.opt_local.modified = false
end, { nargs = '+', complete = 'command' })


local function get_win_filename(winnr)
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  return vim.api.nvim_buf_get_name(bufnr)
end

vim.keymap.set({ 'n' }, '<A-b>', require('buffers').close_unused_buffers, opts)

-- Copy file name with line number
vim.api.nvim_create_user_command('CopyPathWithLine', function()
  local path = get_win_filename(0)
  local lnum, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local location = path .. ":" .. lnum
  vim.cmd([[let @*=']] .. location .. [[']])
end, {})

-- Edit a file at a specific line number
vim.api.nvim_create_user_command('EditLine', function(ctx)
  local file_with_line = ctx.args
  if not file_with_line then
    print("Error: must specify a file")
  else
    local parts = vim.split(file_with_line, ":")
    local path = parts[1]
    local line = parts[2]
    vim.cmd(string.format("edit +%s %s", line, path))
  end
end, { nargs = 1, complete = 'file' })

-- Copy the full path of the current file to the clipboard
vim.api.nvim_create_user_command('CopyPath', function()
  vim.fn.setreg('+', vim.fn.expand('%:p'))
end, {})

vim.keymap.set('n', '<leader>cp', '<cmd>CopyPath<cr>')

-- *** Setup Signs ***
local sign_marks = require('signs')
sign_marks.setup()
vim.keymap.set('n', 'mm', sign_marks.set_anchor)
vim.keymap.set('n', 'ms', sign_marks.set_start)
vim.keymap.set('n', 'me', sign_marks.set_end)

-- *** Setup Scrolling ***
vim.keymap.set('n', '<c-e>', '10<C-e>')
vim.keymap.set('n', '<c-y>', '10<C-y>')

-- *** Setup Indent-base Movement ***
local indents = require('indents')
-- vim.keymap.set({ 'n', 'v' }, '<c-u>', indents.up_same_indent)
-- vim.keymap.set({ 'n', 'v' }, '<c-f>', indents.down_same_indent)
-- vim.keymap.set({ 'n', 'v' }, '<a-n>', indents.up_out_indent)
-- vim.keymap.set({ 'n', 'v' }, '<a-e>', indents.up_in_indent)
-- vim.keymap.set({ 'n', 'v' }, '<a-m>', indents.down_out_indent)
-- vim.keymap.set({ 'n', 'v' }, '<a-,>', indents.down_in_indent)

-- diag
vim.keymap.set({ 'n', 'v' }, '<a-n>', indents.diag_up_out)
vim.keymap.set({ 'n', 'v' }, '<a-e>', indents.diag_up_in)
vim.keymap.set({ 'n', 'v' }, '<a-m>', indents.diag_down_out)
vim.keymap.set({ 'n', 'v' }, '<a-,>', indents.diag_down_in)

local function_picker = require('function_picker')
vim.keymap.set('n', '<leader>su', function_picker.functions)

--- *** Session Management ***
local sessions = require('sessions')
sessions.initialize()

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
  callback = function()
    sessions.load_session()
    vim.cmd("clearjumps")
  end,
  nested = true
})

-- Match the contents of a format string
local query_string = [[
  (macro_invocation
    macro: (identifier) @name (#eq? @name "format")
    (token_tree
      (string_literal
        (string_content) @format))
  )
]]
local query = vim.treesitter.query.parse("rust", query_string)

-- Function to apply highlighting
local function apply_custom_highlighting(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local parser = vim.treesitter.get_parser(bufnr, "rust")
  if parser == nil then
    return
  end

  local tree = parser:parse()[1]
  local ns = vim.api.nvim_create_namespace('RustCustomHighlight')

  -- Run query against syntax tree
  for id, node in query:iter_captures(tree:root(), bufnr) do
    local name = query.captures[id]
    if name == "format" then
      local node_text = vim.treesitter.get_node_text(node, bufnr)
      local start_row, start_col, _, _ = node:range()
      for brace_start, brace_content in node_text:gmatch("()%{(.-)%}()") do
        local brace_end = brace_start + #brace_content

        -- Calculate absolute positions in the buffer
        local hl_start_col = start_col + brace_start
        local hl_end_col = start_col + brace_end

        -- Apply highlight to the range
        local hl = "@variable"
        if brace_content == string.upper(brace_content) then
          hl = "@constant"
        end

        vim.api.nvim_buf_set_extmark(
          bufnr, ns, start_row, hl_start_col, { end_col = hl_end_col, hl_group = hl }
        )
      end
    end
  end
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("Rust", { clear = true }),
  pattern = "rust",
  callback = function()
    apply_custom_highlighting(vim.api.nvim_get_current_buf())
  end,
})
