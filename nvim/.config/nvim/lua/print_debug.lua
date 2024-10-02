local M = {}

local function set_line_number(lnum, cnum)
  vim.api.nvim_buf_set_text(0, lnum - 1, cnum + 1, lnum - 1, cnum + 1, { '(' .. tostring(lnum) .. ')' })
end

M.lua_print = function()
  vim.cmd.normal('yiwovim.print("" ')
  local lnum, cnum = unpack(vim.api.nvim_win_get_cursor(0))
  vim.cmd.normal('a:", ")')
  set_line_number(lnum, cnum)
  vim.cmd.normal('^')
end

M.python_print = function()
  vim.cmd.normal('yiwoprint(f"" ')
  local lnum, cnum = unpack(vim.api.nvim_win_get_cursor(0))
  vim.cmd.normal('a: {"}")')
  set_line_number(lnum, cnum)
end

M.print_rust = function()
  vim.cmd.normal('yiwoprintln!("" ')
  local lnum, cnum = unpack(vim.api.nvim_win_get_cursor(0))
  vim.cmd.normal('a: {}", ");')
  set_line_number(lnum, cnum)
end

return M
