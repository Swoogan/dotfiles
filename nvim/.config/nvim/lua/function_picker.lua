local M = {}

-- Define the function to find lines containing a string
M.find_lines_containing_string = function(bufnr, target)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local matching_lines = {}

  for i, line in ipairs(lines) do
    if vim.fn.match(line, target) > -1 then
      table.insert(matching_lines, { text = line, line = i })
    end
  end

  return matching_lines
end

M.find_functions = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local filename = vim.fn.expand(vim.api.nvim_buf_get_name(bufnr))

  local target_string = "^def"
  local matches = M.find_lines_containing_string(bufnr, target_string)

  local results = {}

  for _, match in ipairs(matches) do
    table.insert(results, {
      lnum = match.line,
      bufnr = bufnr,
      filename = filename,
      text = match.text,
    })
  end

  -- target_string = "^class"
  -- matches = M.find_lines_containing_string(bufnr, target_string)
  --
  -- for _, match in ipairs(matches) do
  --   table.insert(results, {
  --     lnum = match.line,
  --     bufnr = bufnr,
  --     filename = filename,
  --     text = match.text,
  --   })
  -- end

  return results
end


local function test()
  local results = M.find_functions()

  -- Print the result
  print("Functions:")
  for _, result in ipairs(results) do
    print(vim.inspect(result))
  end
end

-- test()

M.functions = function(opts)
  opts = opts or {}

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local make_entry = require("telescope.make_entry")

  pickers.new(opts, {
    prompt_title = "Functions",
    finder = finders.new_table {
      results = M.find_functions(),
      entry_maker = opts.entry_maker or make_entry.gen_from_buffer_lines(opts),
    },
    previewer = conf.grep_previewer(opts),
    sorter = conf.generic_sorter(opts),
  }):find()
end

return M
