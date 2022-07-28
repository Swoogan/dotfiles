local home = os.getenv("HOME")

local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
local M = {
  sep = is_windows and [[\]] or [[/]],
}

-- Join a list of paths together
-- @param ... string list
-- @return string
M.join = function(...)
  return table.concat({ ... }, M.sep)
end

-- Define default values for important path locations
M.confighome = vim.fn.stdpath("config")
M.datahome = vim.fn.stdpath("data")
M.packroot = M.join(M.datahome, "site", "pack")

-- Create a directory
-- @param dir string
M.create_dir = function(dir)
  local state = vim.loop.fs_stat(dir)
  if not state then
    vim.loop.fs_mkdir(dir, 511, function()
      assert("Failed to make path:" .. dir)
    end)
  end
end

-- Returns if the path exists on disk
-- @param p string
-- @return bool
M.exists = function(p)
  local state = vim.loop.fs_stat(p)
  return not (state == nil)
end

---Remove file from file system
---@param path string
M.remove_file = function(path)
  os.execute("rm " .. path)
end

return M
