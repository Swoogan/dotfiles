local utils = require('utils')

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
  -- Todo: this is unreal specific :(
  local build_command = { "pwsh", "-c", "Invoke-EditorBuild" }
  utils.run_buffered(build_command, 'Build Complete')
end

return M
