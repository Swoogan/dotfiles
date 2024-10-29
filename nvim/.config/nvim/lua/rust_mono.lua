local utils = require("utils")

local M = {}

local BUFFER_NAME = "Cargo Output"

--- Parse the cargo errors
local function parse_output(lines)
  local cwd = vim.fn.getcwd()

  local results = {}

  for _, line in ipairs(lines) do
    local file_path, line_number, column_number, msg_level, description = line:match(
      "^(.*):(%d+):(%d+):%s([^:]+):(.*)$"
    )
    if file_path and line_number and column_number then
      local overlap = cwd:match("([^\\]-\\[^\\]-)$")

      if overlap ~= nil and file_path:sub(1, #overlap) == overlap then
        file_path = file_path:gsub("^" .. overlap .. "\\", "")
      end

      local level = "E"
      if vim.startswith(msg_level, "warning") then
        level = "W"
      end

      table.insert(results, {
        file = file_path:gsub("%s", ""),
        line = tonumber(line_number),
        column = tonumber(column_number),
        description = description,
        type = level
      })
    end
  end

  return results
end

--- Save the current buffer if modified
local function save_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_get_option(bufnr, 'modified') then
    vim.cmd('write')
  end
end

--- Parse the output for errors
local function gather_errors(output, errors)
  errors = errors or {}
  if output then
    local lines = vim.split(output, '\r?\n', { trimempty = true })
    local results = parse_output(lines)
    local entries = utils.create_qf_entries(results)

    if #entries > 0 then
      -- concatenate the new entries into the errors array
      for _, v in ipairs(entries) do
        table.insert(errors, v)
      end
    end
  end
end

--- Write the errors to the quickfix window
local function show_errors(errors)
  if #errors > 0 then
    vim.fn.setqflist(errors)
    vim.cmd("botright cwindow")
  end
end

local function run_cargo(command)
  -- Todo: unify with `utils.run_buffered`?
  save_buffer()

  local qf_winid = vim.fn.getqflist({ winid = 0 }).winid
  if qf_winid ~= 0 then
    vim.cmd('cclose')
  end

  -- first save your current window's id, so that we can restore the size later
  local initial_win_id = vim.api.nvim_get_current_win()

  local buf, new_win_id
  if vim.fn.bufexists(BUFFER_NAME) == 1 then
    buf = vim.fn.bufnr(BUFFER_NAME)
    new_win_id = utils.find_or_make_output_window(buf, initial_win_id)
    -- clear the buffer
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
  else
    new_win_id = utils.make_output_window(initial_win_id)
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, BUFFER_NAME)
    vim.api.nvim_win_set_buf(new_win_id, buf)
  end

  local function write_output(output)
    if output then
      local new_text = vim.split(output, '\r?\n', { trimempty = true })
      vim.api.nvim_buf_set_lines(buf, -1, -1, false, new_text)
      local last_line = vim.api.nvim_buf_line_count(buf)
      vim.api.nvim_win_set_cursor(new_win_id, { last_line, 0 })
    end
  end

  local errors = {}
  local function handle_output(_, output)
    vim.schedule(function()
      write_output(output)
      gather_errors(output, errors)
    end)
  end

  local job = vim.system(command, { stderr = handle_output }, function(job)
    vim.schedule(function()
      vim.api.nvim_echo({ { "Build Complete", 'InfoMsg' } }, true, {})
      if job.code ~= 0 then
        show_errors(errors)
        vim.api.nvim_win_close(new_win_id, true)
      end
      -- Set focus back to the initial window
      vim.api.nvim_set_current_win(initial_win_id)
    end)
  end)
  if job.pid <= 0 then
    vim.api.nvim_echo({ { 'Failed to start the job!', 'ErrorMsg' } }, true, {})
  end
end

--- Call `cargo clippy`
M.clippy = function()
  save_buffer()
  local build_command = { "cargo", "clippy", "--message-format=short" }
  utils.run_buffered(build_command, "Build Complete", BUFFER_NAME, utils.OutputTargets.Stderr)
end

--- Call `cargo build`
M.build = function()
  local build_command = { "cargo", "build", "--message-format=short" }
  run_cargo(build_command)
end

--- Call `cargo run`
M.run = function()
  local build_command = { "cargo", "run", "--message-format=short" }
  run_cargo(build_command)
end

return M
