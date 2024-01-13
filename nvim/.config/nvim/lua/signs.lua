local M = {
  group = 'marks',
  names = { m = "MarkAnchor", s = "MarkStart", e = "MarkEnd" }
}

M.set_mark = function(id, name)
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum, cnum = unpack(vim.api.nvim_win_get_cursor(0))
  vim.fn.sign_unplace(M.group, { id = id })
  vim.fn.sign_place(id, M.group, M.names[name], bufnr, { lnum = lnum })
  vim.api.nvim_buf_set_mark(bufnr, name, lnum, cnum, {})
end

M.get_all = function()
  local curr_bufnr = vim.api.nvim_get_current_buf()
  local placed_signs = vim.fn.sign_getplaced(curr_bufnr, { group = M.group })

  local result = {}
  for key, placed_sign in pairs(placed_signs) do
    local new_placed_sign = { bufnr = placed_sign.bufnr, signs = {} }
    local signs = placed_sign.signs
    local mark_name = ""
    for _, sign in pairs(signs) do
      for mark, name in pairs(M.names) do
        if sign.name == name then
          mark_name = mark
        end
      end
      local _, cnum = unpack(vim.api.nvim_buf_get_mark(curr_bufnr, mark_name))
      local new_sign = {
        id = sign.id,
        name = sign.name,
        group = sign.group,
        lnum = sign.lnum,
        cnum = cnum,
        priority = sign.priority
      }
      table.insert(new_placed_sign.signs, new_sign)
    end
    table.insert(result, new_placed_sign)
  end
  return result
end

M.set_all = function(placed_signs)
  -- Todo: unhardcode name, get the cnum somehow
  for _, placed_sign in pairs(placed_signs) do
    local bufnr = placed_sign.bufnr
    local signs = placed_sign.signs
    for _, sign in pairs(signs) do
      vim.fn.sign_place(sign.id, sign.group, sign.name, bufnr, { lnum = sign.lnum })
      for mark, name in pairs(M.names) do
        if sign.name == name then
          vim.api.nvim_buf_set_mark(bufnr, mark, sign.lnum, sign.cnum, {})
        end
      end
    end
  end
end

M.set_anchor = function()
  M.set_mark(1, "m")
end

-- aka top
M.set_start = function()
  M.set_mark(5, "s")
end

-- aka bottom
M.set_end = function()
  M.set_mark(10, "e")
end

M.setup = function()
  vim.fn.sign_define('MarkAnchor', { text = '⚓' })
  vim.fn.sign_define('MarkStart', { text = '🔻' })
  vim.fn.sign_define('MarkEnd', { text = '🔺' })

  -- todo: this doesn't belong here
  vim.fn.sign_define('ImportantLine', { text = '🌟' })

  -- signs = { 'm', 'a', 's', 't', 'n', 'e' }
  -- signs = { 'a', 's', 't', 'n', 'e' }
  -- for _, sign in pairs(signs) do
  --   vim.fn.sign_define('Mark_' .. sign, { text = sign })
  -- end
end

return M
