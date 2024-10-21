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

local function jump_block(direction, lnum, indent)
  while true do
    local next = lnum + direction
    if utils.is_empty(0, next) or vim.fn.indent(next) ~= indent then
      return lnum
    end
    lnum = next
  end
end

local function find_next(type, direction)
  local original_lnum, cnum = unpack(vim.api.nvim_win_get_cursor(0))
  local indent = vim.fn.indent(original_lnum)

  if type == 'out' then
    local next = original_lnum + direction
    local ind = vim.fn.indent(next)
    if ind == -1 then
      return { -1, cnum }
    elseif utils.is_empty(0, next) then
      local lnum = next
      while true do
        lnum = lnum + direction
        ind = vim.fn.indent(lnum)
        if ind == -1 then
          return { -1, cnum }
        elseif ind <= indent then
          break
        end
      end
      return { lnum, ind }
    elseif ind == indent then
      local jump = jump_block(direction, original_lnum, indent)
      return { jump, indent }
    elseif ind < indent then
      return { next, ind }
    elseif ind > indent then
      local lnum = next
      while true do
        lnum = lnum + direction
        ind = vim.fn.indent(lnum)
        if utils.is_empty(0, lnum) then
          goto continue
        elseif ind == -1 then
          return { -1, cnum }
        elseif ind <= indent then
          break
        end
        ::continue::
      end
      return { lnum, ind }
    end

    return { -1, cnum }
  elseif type == 'in' then
    local next = original_lnum + direction
    local ind = vim.fn.indent(next)
    if ind == -1 then
      return { -1, cnum }
    elseif utils.is_empty(0, next) then
      local lnum = next
      while true do
        lnum = lnum + direction
        ind = vim.fn.indent(lnum)
        if ind == -1 then
          return { -1, cnum }
        elseif ind >= indent then
          break
        end
      end
      return { lnum, ind }
    elseif ind == indent then
      local jump = jump_block(direction, original_lnum, indent)
      return { jump, indent }
    elseif ind > indent then
      return { next, ind }
    elseif ind < indent then
      return { original_lnum, cnum }
    end

    return { -1, cnum }
  end
end

--- Move the cursor diagonally up and out on indentation level
M.diag_up_out = function()
  local lnum, cnum = unpack(find_next('out', -1))
  -- print(lnum, cnum)
  if lnum ~= -1 then
    vim.api.nvim_win_set_cursor(0, { lnum, cnum })
  end
end

M.diag_up_in = function()
  local lnum, cnum = unpack(find_next('in', -1))
  -- print(lnum, cnum)
  if lnum ~= -1 then
    vim.api.nvim_win_set_cursor(0, { lnum, cnum })
  end
end

M.diag_down_out = function()
  local lnum, cnum = unpack(find_next('out', 1))
  -- print(lnum, cnum)
  if lnum ~= -1 then
    vim.api.nvim_win_set_cursor(0, { lnum, cnum })
  end
end

M.diag_down_in = function()
  local lnum, cnum = unpack(find_next('in', 1))
  -- print(lnum, cnum)
  if lnum ~= -1 then
    vim.api.nvim_win_set_cursor(0, { lnum, cnum })
  end
end

M.test = function()
  local lnum = jump_block(1, 175)
  vim.print("lnum (192): " .. lnum)
  assert(lnum == 177, "New line should be 177")

  lnum = jump_block(-1, 177)
  vim.print("lnum (192): " .. lnum)
  assert(lnum == 175, "New line should be 175")

  lnum = jump_block(-1, 175)
  vim.print("lnum (192): " .. lnum)
  assert(lnum == 175, "New line should be 175")
end

return M
