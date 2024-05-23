local M = {
  namespace_id = 55
}

---Open the definition when only one window is open
---@param window integer # The window to open the definition in
---@param definition { col: integer, filename: string, lnum: integer } # The location of the definition
local function single_window(window, definition)
  local bufnr = vim.api.nvim_win_get_buf(window)
  local cur_file = string.lower(vim.api.nvim_buf_get_name(bufnr))
  local def_file = string.lower(vim.fs.normalize(definition.filename)) -- This is the filename coming from the LSP

  if def_file == cur_file then
    vim.cmd.normal("m`")
    vim.api.nvim_win_set_cursor(window, { definition.lnum, definition.col - 1 })
  else
    vim.cmd.vsplit()
    vim.cmd.edit(definition.filename)
    local new_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_var(new_win, "references", true)
    vim.api.nvim_win_set_cursor(new_win, { definition.lnum, definition.col - 1 })
    vim.api.nvim_win_set_hl_ns(0, M.namespace_id)
  end
end

---Open the definition when many windows are open
---@param windows integer[] # A list of window handles to open the definition in
---@param definition { col: integer, filename: string, lnum: integer } # The location of the definition
local function multiple_windows(windows, definition)
  local cur_win = vim.api.nvim_get_current_win()
  local cur_buf = vim.api.nvim_win_get_buf(cur_win)
  local cur_file = string.lower(vim.api.nvim_buf_get_name(cur_buf))
  local def_file = string.lower(vim.fs.normalize(definition.filename)) -- This is the filename coming from the LSP

  if def_file == cur_file then
    vim.cmd.normal("m`")
    vim.api.nvim_win_set_cursor(cur_win, { definition.lnum, definition.col - 1 })
    return
  end

  local done = false
  for _, window in pairs(windows) do
    local buf = vim.api.nvim_win_get_buf(window)
    local file = vim.api.nvim_buf_get_name(buf)
    if def_file == string.lower(file) then
      vim.cmd.normal("m`")
      vim.api.nvim_win_set_cursor(window, { definition.lnum, definition.col - 1 })
      done = true
      break
    end
    local ok, refs = pcall(vim.api.nvim_win_get_var, window, "references")
    if ok and refs then
      vim.api.nvim_set_current_win(window)
      vim.cmd.edit(def_file)
      vim.api.nvim_win_set_cursor(window, { definition.lnum, definition.col - 1 })
      done = true
      break
    end
  end

  if not done then
    vim.cmd.vsplit()
    vim.cmd.edit(def_file)
    local new_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_var(new_win, "references", true)
    vim.api.nvim_win_set_cursor(new_win, { definition.lnum, definition.col - 1 })
    vim.api.nvim_win_set_hl_ns(0, M.namespace_id)
  end
end

M.setup = function()
  vim.api.nvim_set_hl(M.namespace_id, "Normal", { bg = "#222730" })
end

--- Replacement for the on_list method for `vim.lsp.buf.definition` that opens definitions in a new vertical split
M.on_list = function(def_list)
  if #def_list > 1 then
    -- double call to lsp :(
    require('telescope.builtin').lsp_definitions()
  else
    local tabnr = vim.api.nvim_get_current_tabpage()
    local windows = vim.api.nvim_tabpage_list_wins(tabnr)
    local item = def_list['items'][1]
    if #windows == 1 then
      single_window(windows[1], item)
    else
      multiple_windows(windows, item)
    end
  end
end

return M
