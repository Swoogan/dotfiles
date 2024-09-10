local utils = require('utils')

local M = {
  word_match = "%w-_"
}

-- Paragraphs

---Move to the first line in the next paragraph
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

---Move to the first line in the current/previous paragraph
M.paragraph_up = function()
  -- Bug: doesn't move to the beginning of the current paragraph
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
local function next_char(content, cnum)
  return string.find(content, '[' .. M.word_match .. ']', cnum + 1)
end

local function next_non_char(content, cnum)
  return string.find(content, '[^' .. M.word_match .. ']', cnum + 1)
end

local function next_token(content, cnum)
  -- Find the next column without a character or digit
  cnum = next_non_char(content, cnum)
  if cnum == nil then
    return nil
  end

  -- Find the next column with a character or a digit
  cnum = next_char(content, cnum)
  if cnum == nil then
    return nil
  end

  return cnum - 1
end

local function curr_char(content, cnum)
  return content:sub(cnum + 1, cnum + 1)
end

local function is_char(content, cnum)
  local char = curr_char(content, cnum)
  return string.match(char, '%w')
end

local function get_line(lnum)
  local bufnr = vim.api.nvim_get_current_buf()

  -- Get the content of the specified line
  return vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]
end

---Move to the beginning of the current/next word
M.forward_word = function()
  local winnr = vim.api.nvim_get_current_win()
  local lnum, cnum = unpack(vim.api.nvim_win_get_cursor(winnr))
  local line_content = get_line(lnum)

  -- Find the start of the next word
  cnum = next_token(line_content, cnum)
  if cnum == nil then
    return
  end

  vim.api.nvim_win_set_cursor(winnr, { lnum, cnum })
end

---Move to the beginning of the current/previous word
M.backward_word = function()
  local winnr = vim.api.nvim_get_current_win()
  local lnum, cnum = unpack(vim.api.nvim_win_get_cursor(winnr))
  local line_content = get_line(lnum)

  local reversed_line = string.reverse(line_content)
  local reversed_cnum = #line_content - cnum

  -- Test if the character is a char
  if is_char(reversed_line, reversed_cnum - 1) then
    -- Find the next column without a character or digit
    local first_non = next_non_char(reversed_line, reversed_cnum)

    -- Move to the start of the line, or the start of the previous word
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
  local next = next_char(reversed_line, reversed_cnum - 1)
  if next == reversed_cnum + 1 then
    local first_non = next_non_char(reversed_line, next)
    if first_non == nil then
      vim.api.nvim_win_set_cursor(winnr, { lnum, 0 })
      return
    else
      local new_cnum = #line_content - (first_non - 1)
      vim.api.nvim_win_set_cursor(winnr, { lnum, new_cnum })
      return
    end
  end

  local first_non = next_non_char(reversed_line, reversed_cnum)
  if first_non == nil then
    vim.api.nvim_win_set_cursor(winnr, { lnum, 0 })
    return
  end

  -- Find the next column with a character or a digit
  local first_char = next_char(reversed_line, first_non)
  if first_char == nil then
    local new_cnum = #line_content - (first_non - 1)
    vim.api.nvim_win_set_cursor(winnr, { lnum, new_cnum })
    return
  end

  -- Find the next column without a character or digit
  local second_non = next_non_char(reversed_line, first_char) or #line_content + 1

  local new_cnum = #line_content - (second_non - 1)
  vim.api.nvim_win_set_cursor(winnr, { lnum, new_cnum })
end

---Move to the end of the current/next word
M.forward_end_word = function()
  local winnr = vim.api.nvim_get_current_win()
  local lnum, cnum = unpack(vim.api.nvim_win_get_cursor(winnr))
  local line_content = get_line(lnum)

  -- Todo: bug: fails when we are on an _
  if is_char(line_content, cnum) then
    local first_non = next_non_char(line_content, cnum)

    -- Move to the end of the line, or the end of the next word
    if first_non == nil then
      vim.api.nvim_win_set_cursor(winnr, { lnum, #line_content })
      return
    elseif first_non - 2 ~= cnum then
      vim.api.nvim_win_set_cursor(winnr, { lnum, first_non - 2 })
      return
    end
  end

  -- Move to the start of the next word
  cnum = next_token(line_content, cnum)
  if cnum == nil then
    return
  end

  -- Move to the end of the current word, or the end of the line
  cnum = next_non_char(line_content, cnum)
  if cnum == nil then
    vim.api.nvim_win_set_cursor(winnr, { lnum, #line_content })
    return
  end

  vim.api.nvim_win_set_cursor(winnr, { lnum, cnum - 2 })
end

---Move to the end of the previous/current word
M.backward_end_word = function()
end

return M
