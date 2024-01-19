local M = {}

M.parse_python_stack_trace = function(stack_trace)
  local results = {}

  local lines = {}
  for line in stack_trace:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end

  local i = 1
  while i <= #lines do
    local file, line_number = lines[i]:match('File "(.-)", line (%d+)')
    if file and line_number then
      local description = lines[i + 1]
      table.insert(results, 1, { file = file, line = tonumber(line_number), description = description })
    end
    i = i + 1
  end

  return results
end

M.create_entries = function(parsed_results)
  local entries = {}

  for _, result in ipairs(parsed_results) do
    table.insert(entries, {
      lnum = result.line, -- Line number
      type = "E",         -- Error type
      filename = result.file,
      text = result.description
    })
  end

  return entries
end

M.stacktrace_to_qflist = function()
  local stack_trace = vim.fn.getreg('+')
  local parsed_results = M.parse_python_stack_trace(stack_trace)
  local entries = M.create_entries(parsed_results)

  if #entries > 0 then
    -- Add the diagnostic entry to the quick fix list
    vim.fn.setqflist(entries)

    -- Open the quick fix window
    vim.cmd("copen")
  end
end

local function test()
  local stack_trace = [[
Traceback (most recent call last):
  File "/home/swoogan/dev/wak.py", line 9, in <module>
    tester()
  File "/home/swoogan/dev/wak.py", line 6, in tester
    test()
  File "/home/swoogan/dev/wak.py", line 2, in test
    raise Exception
Exception
]]

  local parsed_results = M.parse_python_stack_trace(stack_trace)
  local entries = M.create_entries(parsed_results)

  -- Add the diagnostic entry to the quick fix list
  vim.fn.setqflist(entries)

  -- Open the quick fix window
  vim.cmd("copen")
end

-- test()

return M
