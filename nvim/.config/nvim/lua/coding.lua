-- Give the name of the current class or function
local M = {
}

local function find_parent_node(node, node_type)
  while node do
    if node:type() == node_type then
      break
    end
    node = node:parent()
  end
  return node
end

local function get_node_by_type(node_type)
  local ts_utils = require('nvim-treesitter.ts_utils')
  local node = ts_utils.get_node_at_cursor()
  return find_parent_node(node, node_type)
end

local function get_first_line_of_node_text(node, bufnr)
  if not node then return "" end
  local node_text = vim.treesitter.get_node_text(node, bufnr)
  return node_text:match("([^\n]*)\n?")
end

M.print_function = function()
  local node = get_node_by_type('function_definition')
  if not node then
    node = get_node_by_type('function_declaration')
  end
  if not node then
    node = get_node_by_type('function_item')
  end
  local line = get_first_line_of_node_text(node, 0)
  print(line)
end

M.print_class = function()
  local node = get_node_by_type('class_definition')
  local line = get_first_line_of_node_text(node, 0)
  print(line)
end

return M
