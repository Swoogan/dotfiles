local M = {
  data_dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/")
}

local data_file = "sessions.data"

local function random_filename()
  local rand = vim.fn.rand()
  return tostring(rand) .. ".vim"
end

local function read_data()
  local filepath = M.data_dir .. data_file
  local file, _ = io.open(filepath, "r")

  if not file then
    return nil
  end

  local data = {}

  for line in file:lines() do
    local key, value = line:match("'([^']+)'%s*:%s*'(.[^']+)'")
    if key and value then
      local row = {}
      row[key] = value
      table.insert(data, row)
    end
  end

  file:close()

  return data
end

local function write_data(data)
  vim.fn.mkdir(M.data_dir, "p")

  local filepath = M.data_dir .. data_file
  local file, err = io.open(filepath, "w")

  if not file then
    print("Error opening file: " .. err)
  else
    for _, row in pairs(data) do
      for key, value in pairs(row) do
        file:write("'" .. key .. "' : '" .. value .. "'\n")
      end
    end

    file:close()
  end
end

M.add_dir = function(dir)
  local data = read_data()
  -- todo check to see if it doesn't exist properly
  if data and data[dir] == nil then
    table.insert(data, { [dir] = random_filename() })
    write_data(data)
  end
end

M.remove_dir = function(directory)
  local data = read_data()
  local remove = nil
  if data then
    for i, row in ipairs(data) do
      print("i (66):", i)
      print("row (66):", row)
      for dir, _ in pairs(row) do
        print("data (72):", vim.inspect(dir))
        if dir == directory then
          remove = i
        end
      end
    end
    if remove then
      table.remove(data, remove)
      print("data (72):", vim.inspect(data))
      write_data(data)
    end
  end
end

M.initialize = function()
  M.add_dir("/home/swoogan/dev/dotfiles")
  M.add_dir("/home/swoogan/dev/wak")
  local data = read_data()
  print(vim.inspect(data))

  -- M.remove_dir("/home/swoogan/dev/dotfiles")
  -- data = read_data()
end

M.initialize()

return M
