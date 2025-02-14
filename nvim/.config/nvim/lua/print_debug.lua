local M = {}

local function generate_logging(format)
  local lnum, _ = unpack(vim.api.nvim_win_get_cursor(0))
  vim.cmd.normal('yiw')
  local variable = vim.fn.getreg('"')
  local new_line = string.format(format, variable, lnum, variable)
  local current_indent = vim.fn.indent(lnum)
  local indent_str = string.rep(' ', current_indent)
  vim.api.nvim_put({ indent_str .. new_line }, 'l', true, true)
  vim.cmd.normal('k$')
end

M.lua_print = function()
  -- vim.print("lnum (23):", lnum)
  generate_logging('print("%s (%d):" .. vim.inspect(%s))')
end

M.python_print = function()
  -- print(f"issues (302): {issues}")
  generate_logging('print(f"%s (%d): {%s}")')
end

M.print_rust = function()
  -- println!("env (66): {}", env);
  generate_logging('println!("%s (%d): {}", %s);')
end

return M
