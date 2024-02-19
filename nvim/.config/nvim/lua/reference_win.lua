local M = {}

local function single_window(window, item)
  local buf = vim.api.nvim_win_get_buf(window)
  local file = vim.api.nvim_buf_get_name(buf)

  if string.lower(item['filename']) == string.lower(file) then
    -- local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
    -- vim.api.nvim_buf_set_mark(0, "p", lnum, col, {})
    -- vim.api.nvim_buf_set_mark(0, "`", lnum, col, {})
    vim.cmd("normal m`")
    vim.api.nvim_win_set_cursor(window, { item['lnum'], item['col'] - 1 })
  else
    vim.cmd.vsplit()
    vim.cmd.edit(item['filename'])
    local new_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_var(new_win, "references", true)
    vim.api.nvim_win_set_cursor(new_win, { item['lnum'], item['col'] - 1 })
    vim.api.nvim_set_hl(55, "Normal", { bg = "#222730" })
    vim.api.nvim_win_set_hl_ns(0, 55)
  end
end

local function multiple_windows(windows, item)
  local cur_win = vim.api.nvim_get_current_win()
  local cur_buf = vim.api.nvim_win_get_buf(cur_win)
  local cur_file = vim.api.nvim_buf_get_name(cur_buf)
  if string.lower(item['filename']) == string.lower(cur_file) then
    vim.cmd("normal m`")
    vim.api.nvim_win_set_cursor(cur_win, { item['lnum'], item['col'] - 1 })
    return
  end
  local done = false
  for _, window in pairs(windows) do
    local buf = vim.api.nvim_win_get_buf(window)
    local file = vim.api.nvim_buf_get_name(buf)
    if item['filename'] == file then
      vim.cmd("normal m`")
      vim.api.nvim_win_set_cursor(window, { item['lnum'], item['col'] - 1 })
      done = true
      break
    end
    local ok, refs = pcall(vim.api.nvim_win_get_var, window, "references")
    if ok and refs then
      vim.api.nvim_set_current_win(window)
      vim.cmd.edit(item['filename'])
      vim.api.nvim_win_set_cursor(window, { item['lnum'], item['col'] - 1 })
      done = true
      break
    end
  end
  if not done then
    vim.cmd.vsplit()
    vim.cmd.edit(item['filename'])
    local new_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_var(new_win, "references", true)
    vim.api.nvim_win_set_cursor(new_win, { item['lnum'], item['col'] - 1 })
    vim.api.nvim_set_hl(55, "Normal", { bg = "#222730" })
    vim.api.nvim_win_set_hl_ns(0, 55)
  end
end

M.on_list = function(def_list)
  if #def_list > 1 then
    -- double call to lsp :(
    require('telescope.builtin').lsp_definitions()
  else
    local windows = vim.api.nvim_list_wins()
    local item = def_list['items'][1]

    if #windows == 1 then
      single_window(windows[1], item)
    else
      multiple_windows(windows, item)
    end
  end
end

return M
