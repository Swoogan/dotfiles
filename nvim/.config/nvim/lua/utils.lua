local M = {
}

local find_next_line = function(bufnr, direction, start, match)
  local lnum = start
  local total_lines = vim.api.nvim_buf_line_count(bufnr)

  while true do
    lnum = lnum + direction

    if lnum > total_lines or lnum < 1 then
      break
    end

    if match(lnum) then
      return lnum
    end
  end

  return -1
end


---Is the given line empty
---@param lnum integer
---@return boolean
M.is_empty = function(bufnr, lnum)
  local text = vim.api.nvim_buf_get_text(bufnr, lnum - 1, 0, lnum - 1, -1, {})
  return unpack(text) == ""
end

M.find_next_not_empty = function(bufnr, direction, start)
  return find_next_line(bufnr, direction, start, function(lnum) return not M.is_empty(bufnr, lnum) end)
end

M.find_next_empty = function(bufnr, direction, start)
  return find_next_line(bufnr, direction, start, function(lnum) return M.is_empty(bufnr, lnum) end)
end

M.transform_test_name = function()
  -- Takes user input and replaces space with underscore, capitalizes each word
  -- Ex. "this is a test method" => "This_Is_A_Test_Method"
  local input = vim.fn.input("Message: ")
  local output = {}
  for i in string.gmatch(input, "%S+") do
    local first = string.sub(i, 1, 1)
    local rest = string.sub(i, 2, string.len(i))
    local up = string.upper(first)
    table.insert(output, up .. rest)
  end

  local result = ''

  for _, v in pairs(output) do
    result = result .. v .. '_'
  end

  result = string.sub(result, 1, -2)

  local win = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_get_current_buf()
  local cur = vim.api.nvim_win_get_cursor(win)
  local start_row = cur[1] - 1
  local start_col = cur[2] + 1
  vim.api.nvim_buf_set_text(bufnr, start_row, start_col, start_row, start_col, { result })

  local new_col = start_col + string.len(result)
  vim.api.nvim_win_set_cursor(win, { start_row + 1, new_col })
end

return M
