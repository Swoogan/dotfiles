local M = {
}

M.close_unused_buffers = function()
  local keep = {}
  local windows = vim.api.nvim_list_wins()
  for _, window in pairs(windows) do
    local buf = vim.api.nvim_win_get_buf(window)
    table.insert(keep, buf)
  end

  local bufs = vim.api.nvim_list_bufs()
  for _, buf in pairs(bufs) do
    local found = false
    for _, k in pairs(keep) do
      if buf == k then
        found = true
      end
    end
    if not found then
      vim.api.nvim_buf_delete(buf, {})
    end
  end
end

return M
