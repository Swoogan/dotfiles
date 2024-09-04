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
    return {}
  end

  local data = {}

  for line in file:lines() do
    local key, value = line:match("'([^']+)'%s*:%s*'(.[^']+)'")
    if key and value then
      data[key] = value
    end
  end

  file:close()

  return data
end

local function write_data(data)
  vim.fn.mkdir(M.data_dir, "p")

  local filepath = M.data_dir .. data_file
  local fh, err = io.open(filepath, "w")

  if not fh then
    print("Error opening file: " .. err)
  else
    for dir, file in pairs(data) do
      fh:write("'" .. dir .. "' : '" .. file .. "'\n")
    end

    fh:close()
  end
end

M.add_dir = function(dir)
  local data = read_data()
  -- todo check to see if it doesn't exist properly
  if data[dir] == nil then
    data[dir] = random_filename()
    write_data(data)
  end
end

M.remove_dir = function(directory)
  local data = read_data()
  if data[directory] ~= nil then
    data[directory] = nil
    write_data(data)
  end
end

M.save_session = function()
  local dir = vim.fn.getcwd()
  local data = read_data()
  if data[dir] ~= nil then
    local file = data[dir]
    local filepath = M.data_dir .. file
    vim.cmd('mksession! ' .. filepath)
  end
end

M.load_session = function()
  -- turn off session loading when diffing
  if vim.opt.diff:get() then
    return
  end

  local focus = nil
  if vim.fn.argc() > 0 then
    focus = vim.fn.argv()[1]
  end
  local dir = vim.fn.getcwd()
  local data = read_data()
  if data[dir] ~= nil then
    local file = data[dir]
    local filepath = M.data_dir .. file
    vim.cmd('source ' .. filepath)
  end
  if focus ~= nil then
    local bufnr = vim.fn.bufnr(focus, true)
    vim.api.nvim_win_set_buf(0, bufnr)
    -- also consider just not doing the session restore
  end
end


M.initialize = function()
  vim.api.nvim_create_user_command('SessionTrack', function(ctx)
    local dir = ctx.args
    if dir == '' then
      dir = vim.fn.getcwd()
    end
    M.add_dir(dir)
  end, { nargs = '?', complete = 'command' })

  vim.api.nvim_create_user_command('SessionUntrack', function(ctx)
    local dir = ctx.args
    if dir == '' then
      dir = vim.fn.getcwd()
    end
    M.remove_dir(dir)
  end, { nargs = '?', complete = 'command' })
end

M.test = function()
  M.add_dir("/home/swoogan/dev/dotfiles")
  M.add_dir("/home/swoogan/dev/wak")
  local data = read_data()
  print(vim.inspect(data))

  M.remove_dir("/home/swoogan/dev/dotfiles")
  data = read_data()
  print(vim.inspect(data))
end

-- M.test()

return M
