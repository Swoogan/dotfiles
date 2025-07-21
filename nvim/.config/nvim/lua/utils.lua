local M = {
  OutputTargets = {
    Stdout = 1,
    Stderr = 2
  }
}

local find_next_line = function(bufnr, direction, start, match)
  local lnum = start
  local total_lines = vim.api.nvim_buf_line_count(bufnr)

  while true do
    lnum = lnum + direction

    if lnum > total_lines or lnum < 1 then
      break
    end

    if match(lnum) then
      return lnum
    end
  end

  return -1
end


---Is the given line empty
---@param bufnr integer # The buffer to perform the operation on
---@param lnum integer # The line number to perform the operation on
---@return boolean # True if the line is empty
M.is_empty = function(bufnr, lnum)
  local text = vim.api.nvim_buf_get_text(bufnr, lnum - 1, 0, lnum - 1, -1, {})
  return unpack(text) == ""
end

---Find the next non-empty line
---@param bufnr integer # The buffer to perform the operation on
---@param direction integer # The direction to search in. -1 is up and 1 is down
---@param start integer # The line number to start the search from
---@return integer # The line number of the next non-empty line
M.find_next_not_empty = function(bufnr, direction, start)
  return find_next_line(bufnr, direction, start, function(lnum) return not M.is_empty(bufnr, lnum) end)
end

---Find the next empty line
---@param bufnr integer # The buffer to perform the operation on
---@param direction integer # The direction to search in. -1 is up and 1 is down
---@param start integer # The line number to start the search from
---@return integer # The line number of the next empty line
M.find_next_empty = function(bufnr, direction, start)
  return find_next_line(bufnr, direction, start, function(lnum) return M.is_empty(bufnr, lnum) end)
end


---Converts parsed errors to quickfix entries
---@param parsed_results { file: string, line: integer, column: integer, description: string, type: string}
---@return { lnum: integer, type: string, filename: string, text: string}
M.create_qf_entries = function(parsed_results)
  local entries = {}

  for _, result in ipairs(parsed_results) do
    table.insert(entries, {
      lnum = result.line, -- Line number
      type = result.type, -- Error type
      filename = result.file,
      text = result.description
    })
  end

  return entries
end

--- Makes a new small horizontal split at the bottom of the given window
---@param initial_win_id integer The id of the window to split
---@return integer new_win_id The id of the new split
M.make_output_window = function(initial_win_id)
  -- Create a new horizontal split new window at the bottom of the current window
  vim.cmd('botright split')

  -- Get the new window's id
  local new_win_id = vim.api.nvim_get_current_win()

  -- Get the maximum window height, we will use this to calculate 40%
  local total_height = vim.api.nvim_win_get_height(initial_win_id)

  -- Set the height of our new window to be approximately 40% of the total height.
  -- cgs: there's no way this is 40% of the window...
  local SPLIT_SIZE = 0.4
  vim.api.nvim_win_set_height(new_win_id, math.floor(total_height * SPLIT_SIZE))

  return new_win_id
end

--- Get the tab id for a window
---@param winnr integer | nil
---@return integer | nil
M.get_tab_for_window = function(winnr)
  -- Default to current window if none provided
  winnr = winnr or 0

  -- Get all tabs
  local tabs = vim.api.nvim_list_tabpages()

  for _, tab in ipairs(tabs) do
    -- Get all windows in the current tab
    local tab_windows = vim.api.nvim_tabpage_list_wins(tab)

    -- Check if our window is in this tab
    for _, tab_win in ipairs(tab_windows) do
      if tab_win == winnr then
        return tab
      end
    end
  end

  return nil
end

--- See if a given tab is focused
---@param tabnr integer | nil
---@return boolean
M.is_tab_focused = function(tabnr)
  tabnr = tabnr or 0
  local current_tabnr = vim.api.nvim_get_current_tabpage()
  return tabnr == current_tabnr
end

--- Get the id of an existing output window, or make a new one
---@param bufnr integer The id of the buffer to find
---@param initial_winnr integer The id of the window to split
---@return integer new_win_id The id of the new split
M.find_or_make_output_window = function(bufnr, initial_winnr)
  local win_ids = vim.fn.win_findbuf(bufnr)
  if #win_ids > 0 then
    local winnr = win_ids[1]
    local tabnr = M.get_tab_for_window(winnr)
    if M.is_tab_focused(tabnr) then
      return winnr
    else
      vim.api.nvim_win_close(winnr, false)
      local new_winnr = M.make_output_window(initial_winnr)
      vim.api.nvim_win_set_buf(new_winnr, bufnr)
      return new_winnr
    end
  else
    local new_winnr = M.make_output_window(initial_winnr)
    vim.api.nvim_win_set_buf(new_winnr, bufnr)
    return new_winnr
  end
end

--- Delete a buffer with given name
---@param buffer_name string
---@return boolean
M.delete_buffer_by_name = function(buffer_name)
  local buffers = vim.api.nvim_list_bufs()

  for _, buf in ipairs(buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name == buffer_name or name:match(buffer_name .. "$") then
        vim.api.nvim_buf_delete(buf, { force = true })
        return true
      end
    end
  end

  return false
end

--- Run an application in the background and write its output to a new buffer
---@param command string[] The command and its arguments
---@param completion_msg string The message to display upon success
---@param output_source integer Output for the command 1: stdout, 2: stderr
M.run_buffered = function(command, completion_msg, window_name, output_source)
  output_source = output_source or M.OutputTargets.Stdout

  -- first save your current window's id, so that we can restore the size later
  local initial_win_id = vim.api.nvim_get_current_win()

  local buf, new_win_id
  if vim.fn.bufexists(window_name) == 1 then
    buf = vim.fn.bufnr(window_name)
    new_win_id = M.find_or_make_output_window(buf, initial_win_id)
    -- clear the buffer
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
  else
    new_win_id = M.make_output_window(initial_win_id)
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, window_name)
    vim.api.nvim_win_set_buf(new_win_id, buf)
  end

  local function write_output(_, output)
    if output then
      vim.schedule(function()
        local new_text = vim.split(output, '\r?\n', { trimempty = true })
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, new_text)
        if vim.api.nvim_win_is_valid(new_win_id) then
          local last_line = vim.api.nvim_buf_line_count(buf)
          vim.api.nvim_win_set_cursor(new_win_id, { last_line, 0 })
        end
      end)
    end
  end

  local options
  if output_source == M.OutputTargets.Stderr then
    options = { stderr = write_output }
  else
    options = { stdout = write_output }
  end

  local job = vim.system(command, options, function(_)
    vim.schedule(function()
      vim.api.nvim_echo({ { completion_msg, 'InfoMsg' } }, true, {})
      -- Set focus back to the initial window
      vim.api.nvim_set_current_win(initial_win_id)
    end)
  end)
  if job.pid <= 0 then
    vim.api.nvim_echo({ { 'Failed to start the job!', 'ErrorMsg' } }, true, {})
  end
end

M.is_windows = function()
  return vim.uv.os_uname().sysname == "Windows_NT"
end

return M
