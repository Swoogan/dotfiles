local M = {}

M.generate_logging = function(format)
  local lnum, _ = unpack(vim.api.nvim_win_get_cursor(0))
  vim.cmd.normal('"zyiw')
  local variable = vim.fn.getreg('"z')
  local new_line = string.format(format, variable, lnum + 1, variable)
  vim.fn.setreg("y", new_line)
  vim.cmd.normal('oy')

  -- there seems to be a bug where pasting certain things in from `vim.cmd.normal` causes a de-indent in Python
  local current_indent = vim.fn.indent(lnum)
  local new_indent = vim.fn.indent(lnum + 1)
  if new_indent < current_indent then
    vim.cmd.normal('>>')
  end

  -- local indent_str = string.rep(' ', current_indent)
  -- vim.api.nvim_put({ indent_str .. new_line }, 'l', true, true)
  -- vim.cmd.normal('k$')

  -- vim.cmd.normal('$')
  -- local _, cnum = unpack(vim.api.nvim_win_get_cursor(0))
  -- vim.cmd.normal('"yp')
  -- vim.api.nvim_win_set_cursor(0, { lnum, cnum })
  -- vim.cmd.normal('i')
  -- vim.api.nvim_put({'<cr>'}, 'c', true, true)
end

M.lua_print = function()
  -- vim.print("lnum (23):", lnum)
  M.generate_logging('print("%s (%d): " .. vim.inspect(%s))')
end

M.python_print = function()
  -- print(f"issues (302): {issues}")
  M.generate_logging('print(f"%s (%d): {%s}")')
end

M.rust_print = function()
  -- println!("env (66): {}", env);
  M.generate_logging('println!("%s (%d): {}", %s);')
end

M.pwsh_print = function()
  -- Write-Host "env (66): {env}"
  M.generate_logging('Write-Host "`%s (%d): $(%s)"')
end

M.javascript_print = function()
  -- console.log(`issues (302): ${issues}`)
  M.generate_logging('console.log(`%s (%d): ${%s}`);')
end

return M
