local M = {
  data_dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"),
  session_set = false
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

  if M.session_set then
    return
  end

  -- if v:vim_did_enter
  --   call s:init()
  -- else
  --   au VimEnter * call s:init()
  -- endif

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

  M.session_set = true
end

---@class SessionSubcommand
---@field impl fun(args:string[], opts: table) The command implementation
---@field complete? fun(subcmd_arg_lead: string): string[] (optional) Command completions callback, taking the lead of the subcommand's arguments

---@type table<string, SessionSubcommand>
local subcommand_tbl = {
  track = {
    impl = function(args, opts)
      local dir = args[0]
      if dir == nil then
        dir = vim.fn.getcwd()
      end
      M.add_dir(dir)
    end,
    -- This subcommand has no completions
  },
  untrack = {
    impl = function(args, opts)
      local dir = args[0]
      if dir == nil then
        dir = vim.fn.getcwd()
      end
      M.remove_dir(dir)
    end,
    -- This subcommand has no completions
  },
}

---@param opts table :h lua-guide-commands-create
local function session_cmd(opts)
  local fargs = opts.fargs
  local subcommand_key = fargs[1]
  -- Get the subcommand's arguments, if any
  local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
  local subcommand = subcommand_tbl[subcommand_key]
  if not subcommand then
    vim.notify("SessionMan: Unknown command: " .. subcommand_key, vim.log.levels.ERROR)
    return
  end
  -- Invoke the subcommand
  subcommand.impl(args, opts)
end

M.initialize = function()
  vim.api.nvim_create_user_command("SessionMan", session_cmd, {
    nargs = "+",
    desc = "Track sessions for certain folders",
    complete = function(arg_lead, cmdline, _)
      -- Get the subcommand.
      local subcmd_key, subcmd_arg_lead = cmdline:match("^['<,'>]*SessionMan[!]*%s(%S+)%s(.*)$")
      if subcmd_key
          and subcmd_arg_lead
          and subcommand_tbl[subcmd_key]
          and subcommand_tbl[subcmd_key].complete
      then
        -- The subcommand has completions. Return them.
        return subcommand_tbl[subcmd_key].complete(subcmd_arg_lead)
      end
      -- Check if cmdline is a subcommand
      if cmdline:match("^['<,'>]*SessionMan[!]*%s+%w*$") then
        -- Filter subcommands that match
        local subcommand_keys = vim.tbl_keys(subcommand_tbl)
        return vim.iter(subcommand_keys)
            :filter(function(key)
              return key:find(arg_lead) ~= nil
            end)
            :totable()
      end
    end,
    bang = true, -- If you want to support ! modifiers
  })
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
