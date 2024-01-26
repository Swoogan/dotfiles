local utils = require('utils')

local M = {
  word_match = "%w-_"
}

-- Paragraphs

M.paragraph_down = function()
  local lnum, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local bufnr = vim.api.nvim_get_current_buf()
  if not utils.is_empty(bufnr, lnum) then
    lnum = utils.find_next_empty(bufnr, 1, lnum)
    if lnum == -1 then
      return
    end
  end
  lnum = utils.find_next_not_empty(bufnr, 1, lnum)
  if lnum > -1 then
    vim.api.nvim_win_set_cursor(0, { lnum, vim.fn.indent(lnum) })
  end
end

M.paragraph_up = function()
  local winnr = vim.api.nvim_get_current_win()
  local lnum, _ = unpack(vim.api.nvim_win_get_cursor(winnr))
  local bufnr = vim.api.nvim_get_current_buf()
  if not utils.is_empty(bufnr, lnum) then
    lnum = utils.find_next_empty(bufnr, -1, lnum)
    if lnum == -1 then
      return
    end
  end
  lnum = utils.find_next_not_empty(bufnr, -1, lnum)
  if lnum == -1 then
    return
  end
  lnum = utils.find_next_empty(bufnr, -1, lnum)
  lnum = math.max(lnum + 1, 1)
  local cnum = math.max(vim.fn.indent(lnum), 0)
  vim.api.nvim_win_set_cursor(winnr, { lnum, cnum })
end

-- Words

M.forward_word = function()
  local winnr = vim.api.nvim_get_current_win()
  local lnum, cnum = unpack(vim.api.nvim_win_get_cursor(winnr))
  local bufnr = vim.api.nvim_get_current_buf()

  -- Get the content of the specified line
  local line_content = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]

  -- Find the next column without a character or digit
  local next_column = string.find(line_content, '[^' .. M.word_match .. ']', cnum + 1)

  if next_column == nil then
    return
  end

  -- Find the next column with a character or a digit
  next_column = string.find(line_content, '[' .. M.word_match .. ']', next_column + 1)
  if next_column == nil then
    return
  end

  vim.api.nvim_win_set_cursor(winnr, { lnum, next_column - 1 })
end

M.backward_word = function()
  local winnr = vim.api.nvim_get_current_win()
  local lnum, cnum = unpack(vim.api.nvim_win_get_cursor(winnr))
  local bufnr = vim.api.nvim_get_current_buf()

  -- Get the content of the specified line
  local line_content = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]

  local reversed_line = string.reverse(line_content)
  local reversed_cnum = #line_content - cnum

  local char = reversed_line:sub(reversed_cnum, reversed_cnum)

  -- Test if the character is a digit
  if string.match(char, '%w') then
    -- Find the next column without a character or digit
    local first_non = string.find(reversed_line, '[^' .. M.word_match .. ']', reversed_cnum)

    if first_non == nil then
      vim.api.nvim_win_set_cursor(winnr, { lnum, 0 })
      return
    elseif first_non ~= reversed_cnum + 1 then
      local new_cnum = #line_content - (first_non - 1)
      vim.api.nvim_win_set_cursor(winnr, { lnum, new_cnum })
      return
    end
  end

  -- Find the next column without a character or digit
  local first_non = string.find(reversed_line, '[^' .. M.word_match .. ']', reversed_cnum)

  if first_non == nil then
    vim.api.nvim_win_set_cursor(winnr, { lnum, 0 })
    return
  end

  -- Find the next column with a character or a digit
  local first_char = string.find(reversed_line, '[' .. M.word_match .. ']', first_non + 1)
  if first_char == nil then
    local new_cnum = #line_content - (first_non - 1)
    vim.api.nvim_win_set_cursor(winnr, { lnum, new_cnum })
    return
  end

  -- Find the next column without a character or digit
  local second_non = string.find(reversed_line, '[^' .. M.word_match .. ']', first_char + 1) or #line_content + 1

  local new_cnum = #line_content - (second_non - 1)
  vim.api.nvim_win_set_cursor(winnr, { lnum, new_cnum })
end

return M
