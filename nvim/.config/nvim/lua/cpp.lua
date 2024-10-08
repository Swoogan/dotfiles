local M = {}

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
  -- first save your current window's id, so that we can restore the size later
  local initial_win_id = vim.api.nvim_get_current_win()

  -- Create a new horizontal split new window at the bottom of the current window
  vim.cmd('botright split')

  -- Get the new window's id
  local new_win_id = vim.api.nvim_get_current_win()

  -- Get the maximum window height, we will use this to calculate 40%
  local total_height = vim.api.nvim_win_get_height(initial_win_id)

  -- Set the height of our new window to be approximately 40% of the total height.
  vim.api.nvim_win_set_height(new_win_id, math.floor(total_height * 0.4))

  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set that buffer in the new window we have created
  vim.api.nvim_win_set_buf(new_win_id, buf)

  local function write_output(_, output)
    if output then
      vim.schedule(function()
        local new_text = vim.split(output, '\r\n', { trimempty = true })
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, new_text)
        local last_line = vim.api.nvim_buf_line_count(buf)
        vim.api.nvim_win_set_cursor(new_win_id, { last_line, 0 })
      end)
    end
  end

  -- Todo: this is unreal specific :(
  local build_command = { "pwsh", "-c", "Invoke-EditorBuild" }
  local job = vim.system(build_command, { stdout = write_output }, function(_)
    vim.schedule(function()
      vim.api.nvim_echo({ { 'Build Complete', 'InfoMsg' } }, true, {})
      -- Set focus back to the initial window
      vim.api.nvim_set_current_win(initial_win_id)
    end)
  end)
  if job.pid <= 0 then
    vim.api.nvim_echo({ { 'Failed to start the job!', 'ErrorMsg' } }, true, {})
  end
end

return M
