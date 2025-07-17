local utils = require('utils')

local M = {
}

local BUFFER_NAME = "Build Output"

--- Parse the build errors
local function parse_output(lines)
  local cwd = vim.fn.getcwd()

  local results = {}

  for _, line in ipairs(lines) do
    local file_path, line_number, _, description = line:match(
      "^(.+)%((%d+)%):%serror%s([^:]+):%s(.+)"
    )
    if file_path and line_number then
      local overlap = cwd:match("([^\\]-\\[^\\]-)$")

      if overlap ~= nil and file_path:sub(1, #overlap) == overlap then
        file_path = file_path:gsub("^" .. overlap .. "\\", "")
      end

      table.insert(results, {
        file = file_path:gsub("%s", ""),
        line = tonumber(line_number),
        column = 0,
        description = description,
        type = "E"
      })
    end
  end

  return results
end

--- Save the current buffer if modified
local function save_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.api.nvim_get_option_value('modified', { buf = bufnr }) then
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


local function run_build(command)
  -- Todo: unify with `utils.run_buffered`
  save_buffer()

  local qf_winid = vim.fn.getqflist({ winid = 0 }).winid
  if qf_winid ~= 0 then
    vim.cmd('cclose')
  end

  -- first save your current window's id, so that we can restore the size later
  local initial_winnr = vim.api.nvim_get_current_win()

  local bufnr, new_winnr
  if vim.fn.bufexists(BUFFER_NAME) == 1 then
    bufnr = vim.fn.bufnr(BUFFER_NAME)
    new_winnr = utils.find_or_make_output_window(bufnr, initial_winnr)
    -- clear the buffer
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
  else
    new_winnr = utils.make_output_window(initial_winnr)
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, BUFFER_NAME)
    vim.api.nvim_win_set_buf(new_winnr, bufnr)
  end

  local function write_output(output)
    if output then
      local new_text = vim.split(output, '\r?\n', { trimempty = true })
      vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, new_text)
      local last_line = vim.api.nvim_buf_line_count(bufnr)
      if vim.api.nvim_win_is_valid(new_winnr) then
        vim.api.nvim_win_set_cursor(new_winnr, { last_line, 0 })
      end
    end
  end

  local errors = {}
  local function handle_output(_, output)
    vim.schedule(function()
      write_output(output)
      gather_errors(output, errors)
    end)
  end

  local job = vim.system(command, { stdout = handle_output }, function(job)
    vim.schedule(function()
      vim.api.nvim_echo({ { "Build Complete", 'InfoMsg' } }, true, {})
      if job.code ~= 0 then
        show_errors(errors)
        vim.api.nvim_win_close(new_winnr, true)
      end
      -- Set focus back to the initial window
      if vim.api.nvim_win_is_valid(initial_winnr) then
        vim.api.nvim_set_current_win(initial_winnr)
      end
    end)
  end)
  if job.pid <= 0 then
    vim.api.nvim_echo({ { 'Failed to start the job!', 'ErrorMsg' } }, true, {})
  end
end

-- Turns out that clangd has the ability builtin (ClangdSwitchSourceHeader)
M.toggle_header = function()
  local file = vim.fn.expand("%:t:r")
  local path = vim.fn.expand("%:p:h")
  local up_one = vim.fs.normalize(path .. "/..")
  local header = file .. ".h"
  local header_pattern = "^" .. header .. "$"

  local cmd = { "fd", "--search-path=" .. up_one, header_pattern }
  vim.system(cmd, {}, function(obj)
    -- Open the first matching header
    if obj.code == 0 then
      local lines = vim.split(obj.stdout, "\n")
      -- For now, just assume the first is correct
      if #lines >= 1 then
        vim.schedule(function()
          local header_path = vim.fs.normalize(lines[1])
          vim.cmd("edit " .. header_path)
        end)
      end
    end
  end)
end

M.build_editor = function()
  -- Todo: this is Unreal specific :(
  local build_command = { "pwsh", "-c", "Invoke-EditorBuild; exit $LASTEXITCODE" }
  run_build(build_command)
end

M.close_build_output = function()
  utils.delete_buffer_by_name(BUFFER_NAME)
end


return M
