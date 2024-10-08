local utils = require("utils")
local M = {}

---Parse the Python stacktrace into entries
---@param stack_trace string
---@return { file: string, line: integer, column: integer, description: string, type: string}
M.parse_python_stack_trace = function(stack_trace)
  local lines = {}
  for line in stack_trace:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end

  local results = {}
  local i = 1
  while i < #lines do
    local file, line_number = lines[i]:match('File "(.-)", line (%d+)')
    if file and line_number then
      local description = lines[i + 1]
      table.insert(results, 1, { file = file, line = tonumber(line_number), description = description, type = "E" })
    end
    i = i + 1
  end

  table.insert(results, 1, { file = nil, line = nil, description = lines[#lines] })

  return results
end

---Parse a Lua stacktrace into entries
---@param stack_trace string
---@return { file: string, line: integer, column: integer, description: string, type: string}
M.parse_lua_stack_trace = function(stack_trace)
  local lines = vim.split(stack_trace, '\n')

  local results = {}

  for _, line in ipairs(lines) do
    local file, line_number, description = line:match("([^:]+):(%d+):%s(.+)")
    if file and line_number and description then
      table.insert(results,
        { file = file:gsub("%s", ""), line = tonumber(line_number), description = description, type = "E" })
    end
  end

  return results
end

M.stacktrace_to_qflist = function()
  local stack_trace = vim.fn.getreg('+')
  local filetype = vim.bo.filetype

  -- Check if the filetype is set
  if not filetype or filetype == '' then
    return
  end

  local parsed_results
  if filetype == 'python' then
    parsed_results = M.parse_python_stack_trace(stack_trace)
  elseif filetype == 'lua' then
    parsed_results = M.parse_lua_stack_trace(stack_trace)
  else
    return
  end

  local entries = utils.create_qf_entries(parsed_results)

  if #entries > 0 then
    -- Add the diagnostic entries to the quick fix list
    vim.fn.setqflist(entries)

    -- Open the quick fix window
    vim.cmd("copen")
  end
end

local function test()
  local stack_trace = [[
Traceback (most recent call last):
  File "/home/swoogan/dev/wak.py", line 18, in <module>
    tester()
  File "/home/swoogan/dev/wak.py", line 15, in tester
    test()
  File "/home/swoogan/dev/wak.py", line 3, in test
    raise Exception(msg)
Exception: something happened
]]

  local parsed_results = M.parse_python_stack_trace(stack_trace)
  local entries = utils.create_qf_entries(parsed_results)

  -- Add the diagnostic entry to the quick fix list
  vim.fn.setqflist(entries)

  -- Open the quick fix window
  vim.cmd("copen")
end

local function test2()
  local input_text = [[
Error executing vim.schedule lua callback: /home/swoogan/.config/nvim/lua/reference_win.lua:81: Expected 1 argument
stack traceback:
        [C]: in function 'nvim_tabpage_list_wins'
        /home/swoogan/.config/nvim/lua/reference_win.lua:81: in function 'on_list'
        ...im54MxR5/usr/share/nvim/runtime/lua/vim/lsp/handlers.lua:402: in function 'handler'
        ...nt_nvim54MxR5/usr/share/nvim/runtime/lua/vim/lsp/buf.lua:52: in function 'handler'
        ....mount_nvim54MxR5/usr/share/nvim/runtime/lua/vim/lsp.lua:1393: in function ''
        vim/_editor.lua: in function <vim/_editor.lua:0>
]]

  -- Split the input text into lines
  local lines = vim.split(input_text, '\n')

  -- Iterate through each line
  for _, line in ipairs(lines) do
    -- Extract file, line number, and message using pattern matching
    local file, line, message = line:match("([^:]+):(%d+):%s(.+)")

    -- Print the results
    if file and line and message then
      print("File: " .. file)
      print("Line: " .. line)
      print("Message: " .. message)
      print("------------------------")
    end
  end
end

-- test()
-- test2()

return M
