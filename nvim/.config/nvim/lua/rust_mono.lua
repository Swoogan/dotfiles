local utils = require("utils")

local M = {}

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
    vim.api.nvim_command('write')
  end
end

--- Parse the output for errors and write to the quickfix window
local function show_errors(_, output)
  if output then
    local results = parse_output(output)
    local entries = utils.create_qf_entries(results)

    if #entries > 0 then
      vim.fn.setqflist(entries)
      vim.cmd("botright cwindow")
    else
      vim.api.nvim_echo({ { "Cargo command successful", 'MsgArea' } }, true, {})
      vim.cmd("cclose")
    end
  end
end

local function test(_, data)
  if data then
    for _, line in ipairs(data) do
      if line then
        vim.api.nvim_echo({ { line, 'MsgArea' } }, true, {})
      end
    end
  end
end

--- Call `cargo build`
M.build = function()
  save_buffer()
  -- Todo: make this show the build output live
  -- vim.fn.jobstart(build_command, { stderr_buffered = true, on_stdout = test, on_stderr = show_errors })
  -- vim.fn.jobstart(build_command, { on_stderr = show_errors })
  vim.api.nvim_echo({ { "Starting `cargo build`", 'MsgArea' } }, true, {})
  local build_command = { "cargo", "build", "--message-format=short" }
  local job_id = vim.fn.jobstart(build_command, { stderr_buffered = true, on_stderr = show_errors })
  if job_id <= 0 then
    vim.api.nvim_echo({ { 'Failed to start the job!', 'ErrorMsg' } }, true, {})
    return
  end
end

--- Call `cargo run`
M.run = function()
  save_buffer()

  vim.api.nvim_echo({ { "Starting `cargo run`", 'MsgArea' } }, true, {})
  local build_command = { "cargo", "run", "--message-format=short" }
  local job_id = vim.fn.jobstart(build_command, { stderr_buffered = true, on_stderr = show_errors })
  if job_id <= 0 then
    vim.api.nvim_echo({ { 'Failed to start the job!', 'ErrorMsg' } }, true, {})
    return
  end
end

return M
