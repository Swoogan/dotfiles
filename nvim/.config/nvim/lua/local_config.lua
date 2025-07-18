local M = {}

M.keymaps = function()
  local ok, module = pcall(require, "keymaps")
  if ok then
    module.add_maps()
  end
end

M.load_config = function()
  local ok, module = pcall(require, "config")
  if ok then
    return module.config
  end
  return nil
end

return M
