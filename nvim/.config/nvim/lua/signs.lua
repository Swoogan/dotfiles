local M = {
  group = 'marks',
  names = { m = "MarkAnchor", s = "MarkStart", e = "MarkEnd" },
  data = {
    anchor = { mark = 'm', sign = 'MarkAnchor', text = '⚓' },
    start = { mark = 's', sign = 'MarkStart', text = '🔻' },
    ['end'] = { mark = 'e', sign = 'MarkEnd', text = '🔺' },
  }
}

M.set_mark = function(name)
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum, cnum = unpack(vim.api.nvim_win_get_cursor(0))
  local sign = M.data[name]
  vim.fn.sign_unplace(name, { id = bufnr })
  vim.fn.sign_place(bufnr, name, sign.sign, bufnr, { lnum = lnum })
  vim.api.nvim_buf_set_mark(bufnr, sign.mark, lnum, cnum, {})
end

M.get_all = function()
  local bufnr = vim.api.nvim_get_current_buf()

  local result = {}
  for name, sign in pairs(M.data) do
    local placed_signs = vim.fn.sign_getplaced(bufnr, { group = name })

    for _, placed_sign in pairs(placed_signs) do
      local new_placed_sign = { bufnr = placed_sign.bufnr, signs = {} }
      for _, existing in pairs(placed_sign.signs) do
        local _, cnum = unpack(vim.api.nvim_buf_get_mark(bufnr, sign.mark))
        local new_sign = {
          id = existing.id,
          name = sign.sign,
          group = existing.group,
          lnum = existing.lnum,
          cnum = cnum,
          priority = existing.priority
        }
        table.insert(new_placed_sign.signs, new_sign)
      end
      table.insert(result, new_placed_sign)
    end
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
  M.set_mark("anchor")
end

-- aka top
M.set_start = function()
  M.set_mark("start")
end

-- aka bottom
M.set_end = function()
  M.set_mark("end")
end

M.setup = function()
  -- todo: this doesn't belong here
  vim.fn.sign_define('ImportantLine', { text = '🌟' })

  for _, sign in pairs(M.data) do
    vim.fn.sign_define(sign.sign, { text = sign.text })
  end


  -- signs = { 'a', 't', 'n', 'o' }
  -- for _, sign in pairs(signs) do
  --   vim.fn.sign_define('Mark_' .. sign, { text = sign })
  -- end
end

return M
