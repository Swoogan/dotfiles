local utils = require('utils')

local M = {
}

---Find the next line, moving in the given direction, that is of the given type
---@param type string # A type of 'same' (same indent level), 'in' (indented) or 'out' (dedented)
---@param direction integer # An integer, either 1 or -1 indicating to move down or up, respectively
---@return integer[] # A list containing the line number as the first element and column number as the second
local function find(type, direction)
  local winnr = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum, cnum = unpack(vim.api.nvim_win_get_cursor(winnr))
  local indent = vim.fn.indent(lnum)

  while true do
    lnum = lnum + direction
    local ind = vim.fn.indent(lnum)

    if ind == -1 then
      break
    end

    if utils.is_empty(bufnr, lnum) then
      goto continue
    end

    local delta = ind - indent
    if type == 'same' and delta == 0 then
      return { lnum - direction, ind }
    elseif type == 'out' and delta < 0 then
      return { lnum, ind }
    elseif type == 'in' and delta > 0 then
      return { lnum, ind }
    end

    ::continue::
  end

  return { -1, cnum }
end

-- *** Standard movement ***

M.up_same_indent = function()
  -- Todo: stop when exiting scope
  local lnum, cnum = unpack(find('same', -1))
  if lnum ~= -1 then
    vim.api.nvim_win_set_cursor(0, { lnum, cnum })
  end
end

M.down_same_indent = function()
  local lnum, cnum = unpack(find('same', 1))
  if lnum ~= -1 then
    vim.api.nvim_win_set_cursor(0, { lnum, cnum })
  end
end

M.up_out_indent = function()
  local lnum, cnum = unpack(find('out', -1))
  if lnum ~= -1 then
    print("lnum", lnum)
    vim.api.nvim_win_set_cursor(0, { lnum, cnum })
  end
end

M.down_out_indent = function()
  local lnum, cnum = unpack(find('out', 1))
  if lnum ~= -1 then
    print("lnum", lnum)
    vim.api.nvim_win_set_cursor(0, { lnum, cnum })
  end
end

M.up_in_indent = function()
  local lnum, cnum = unpack(find('in', -1))
  print("lnum", lnum)
  if lnum ~= -1 then
    vim.api.nvim_win_set_cursor(0, { lnum, cnum })
  end
end

M.down_in_indent = function()
  local lnum, cnum = unpack(find('in', 1))
  if lnum ~= -1 then
    vim.api.nvim_win_set_cursor(0, { lnum, cnum })
  end
end

-- *** Diagonal movement ***

local function find_next(type, direction)
  local lnum, cnum = unpack(vim.api.nvim_win_get_cursor(0))
  local indent = vim.fn.indent(lnum)

  while true do
    lnum = lnum + direction
    local ind = vim.fn.indent(lnum)

    if ind == -1 then
      break
    end

    if utils.is_empty(0, lnum) then
      goto continue
    end

    local delta = ind - indent
    -- vim.print("delta (112):", delta)
    -- vim.print("lnum (113):", lnum)
    if type == 'out' then
      if delta <= 0 then
        return { lnum, ind }
      else
        return { lnum - direction, indent }
      end
    elseif type == 'in' then
      if delta >= 0 then
        return { lnum, ind }
      else
        return { lnum - direction, indent }
      end
    end

    ::continue::
  end

  return { -1, cnum }
end

local function find_next_not_empty(direction)
  local lnum, cnum = unpack(vim.api.nvim_win_get_cursor(0))

  while true do
    lnum = lnum + direction
    local ind = vim.fn.indent(lnum)
    if ind == -1 then
      break
    end

    if utils.is_empty(0, lnum) ~= true then
      return { lnum, ind }
    end
  end

  return { -1, cnum }
end

--- Move the cursor diagonally up and out on indentation level
M.diag_up_out = function()
  local lnum, cnum = unpack(find_next('out', -1))
  print(lnum, cnum)
  if lnum ~= -1 then
    vim.api.nvim_win_set_cursor(0, { lnum, cnum })
  end
end

M.diag_up_in = function()
  local lnum, cnum = unpack(find_next('in', -1))
  print(lnum, cnum)
  if lnum ~= -1 then
    vim.api.nvim_win_set_cursor(0, { lnum, cnum })
  end
end

M.diag_down_out = function()
  local lnum, cnum = unpack(find_next('out', 1))
  print(lnum, cnum)
  if lnum ~= -1 then
    vim.api.nvim_win_set_cursor(0, { lnum, cnum })
  end
end

M.diag_down_in = function()
  local lnum, cnum = unpack(find_next('in', 1))
  print(lnum, cnum)
  if lnum ~= -1 then
    vim.api.nvim_win_set_cursor(0, { lnum, cnum })
  end
end

return M
