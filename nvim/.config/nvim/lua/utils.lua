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

M.transform_test_name = function()
  -- Takes user input and replaces space with underscore, capitalizes each word
  -- Ex. "this is a test method" => "This_Is_A_Test_Method"
  local input = vim.fn.input("Message: ")
  local output = {}
  for i in string.gmatch(input, "%S+") do
    local first = string.sub(i, 1, 1)
    local rest = string.sub(i, 2, string.len(i))
    local up = string.upper(first)
    table.insert(output, up .. rest)
  end

  local result = ''

  for _, v in pairs(output) do
    result = result .. v .. '_'
  end

  result = string.sub(result, 1, -2)

  local win = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_get_current_buf()
  local cur = vim.api.nvim_win_get_cursor(win)
  local start_row = cur[1] - 1
  local start_col = cur[2] + 1
  vim.api.nvim_buf_set_text(bufnr, start_row, start_col, start_row, start_col, { result })

  local new_col = start_col + string.len(result)
  vim.api.nvim_win_set_cursor(win, { start_row + 1, new_col })
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

--- Get the id of an existing output window, or make a new one
---@param bufnr integer The id of the buffer to find
---@param initial_win_id integer The id of the window to split
---@return integer new_win_id The id of the new split
M.find_or_make_output_window = function(bufnr, initial_win_id)
  local win_ids = vim.fn.win_findbuf(bufnr)
  if #win_ids > 0 then
    return win_ids[1]
  else
    local new_win_id = M.make_output_window(initial_win_id)
    vim.api.nvim_win_set_buf(new_win_id, bufnr)
    return new_win_id
  end
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

return M
