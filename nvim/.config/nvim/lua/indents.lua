local M = {
}

local function is_empty(lnum)
  print("is empty lnum:", lnum)
  local text = vim.api.nvim_buf_get_text(0, lnum - 1, 0, lnum - 1, -1, {})
  print("is empty lnum:", lnum)
  return unpack(text) == ""
end

local function has_deindent_between(indent, start, stop)
  local found = false
  for i = start, stop do
    local ind = vim.fn.indent(i)
    if ind < indent then
      found = true
    end
  end
  return found
end

local function find(type, direction)
  local lnum, cnum = unpack(vim.api.nvim_win_get_cursor(0))
  local indent = vim.fn.indent(lnum)
  while true do
    lnum = lnum + direction
    print("lnum ", lnum)
    local ind = vim.fn.indent(lnum)
    print("ind ", ind)
    if ind == -1 then
      break
    end

    if is_empty(lnum) then
      goto continue
    end

    local delta = ind - indent
    print(lnum, delta)
    if type == 'same' and delta == 0 then
      return { lnum, cnum }
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

M.diag_up_out = function()
end

M.diag_up_in = function()
end

M.diag_down_out = function()
end

M.diag_down_in = function()
end
return M
