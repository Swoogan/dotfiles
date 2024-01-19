local M = {
}

-- Define the function to find lines containing a string
function find_lines_containing_string(bufnr, target)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local matching_lines = {}

  for i, line in ipairs(lines) do
    if vim.fn.match(line, target) > -1 then
      table.insert(matching_lines, i)
    end
  end

  return matching_lines
end

M.find_functions = function()
  if vim.bo.filetype == "python" then
    -- Example: Find lines containing the string "example" in the current buffer
    local current_bufnr = vim.api.nvim_get_current_buf()
    local target_string = "^\\s*def"
    local result = find_lines_containing_string(current_bufnr, target_string)

    -- Print the result
    print("Lines containing '" .. target_string .. "':")
    for _, line_number in ipairs(result) do
      print(line_number .. ": " .. vim.api.nvim_buf_get_lines(current_bufnr, line_number - 1, line_number, false)[1])
    end
  end
end

return M
