local M = {}

M.keymaps = function()
  local ok, module = pcall(require, "local.keymaps")
  if ok then
    module.add_maps()
  end
end

M.luasnips = function()
  local ok, module = pcall(require, "local.luasnips")
  if ok then
    module.add_snippets()
  end
end

M.lang = function()
  local ok, module = pcall(require, "local.lang")
  if ok then
    -- module.???()
  end
end

M.load_config = function()
  local ok, module = pcall(require, "local.config")
  if ok then
    return module.config
  end
  return nil
end

return M
