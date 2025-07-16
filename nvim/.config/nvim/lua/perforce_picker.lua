local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local previewers = require("telescope.previewers")
local make_entry = require("telescope.make_entry")

local M = {}

M.opened = function(opts)
  opts = opts or {}

  local find_command = { "p4", "-F", "%clientFile%", "fstat", "-Ro", "..." }
  opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)

  pickers.new(opts, {
    prompt_title = "Perforce Opened",
    finder = finders.new_oneshot_job(find_command, opts),
    sorter = conf.generic_sorter(opts)
  }):find()
end

M.changelists = function(opts)
  opts = opts or {}

  --  p4 changes -u (p4 -ztag -F "%userName%" info) -s pending -r
  local find_command = { "p4", "changes", "-u", "(p4 -ztag -F %userName% info)", "-s", "pending", "-r" }
  opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)

  pickers.new(opts, {
    prompt_title = "Perforce Changelists",
    finder = finders.new_oneshot_job(find_command, opts),
    sorter = conf.generic_sorter(opts)
  }):find()
end

M.diff_locations = function()
  local cached_diff = vim.env.P4DIFF
  vim.env.P4DIFF = 'git --no-pager diff --unified=0'
  local current_file = vim.fn.expand('%:p')
  local diff_content = vim.fn.system('p4 diff ' .. current_file)
  vim.env.P4DIFF = cached_diff
  local locations = {}

  -- Parse the diff to get locations
  for line in diff_content:gmatch("[^\r?\n]+") do
    local start_line, chunk_size = line:match("^@@ %-%d+,?%d+ %+(%d+),?(%d*)%s@@")
    if start_line then
      local line_nbr = tonumber(start_line) or 1
      local buf_line = vim.api.nvim_buf_get_lines(0, line_nbr - 1, line_nbr, false)[1]
      table.insert(locations, {
        line = string.format("%x, %s: %s", line_nbr, chunk_size, buf_line),
        lnum = tonumber(start_line),
        chunk_size = tonumber(chunk_size)
      })
    end
  end

  local ns = vim.api.nvim_create_namespace("")

  local jump_to_line = function(self, bufnr, entry)
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    -- Cannot specify -1 for end_col. See,
    -- https://github.com/neovim/neovim/issues/27469
    local line = vim.api.nvim_buf_get_lines(bufnr, entry.lnum - 1, entry.lnum, false)[1]
    local end_col = line and string.len(line) or 0

    vim.api.nvim_buf_set_extmark(
      bufnr, ns, entry.lnum - 1, 0, { end_col = end_col, hl_group = "TelescopePreviewLine" }
    )
    vim.api.nvim_win_set_cursor(self.state.winid, { entry.lnum, 0 })
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd('normal! zz')
    end)
  end

  -- Create the picker
  pickers.new({}, {
    prompt_title = "Diff Locations",
    finder = finders.new_table({
      results = locations,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.line,
          ordinal = entry.line,
          path = current_file,
          lnum = entry.lnum,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      title = "Diff Preview",
      define_preview = function(self, entry)
        local p = entry.path
        return conf.buffer_previewer_maker(p, self.state.bufnr, {
          bufname = self.state.bufname,
          winid = self.state.winid,
          callback = function(bufnr)
            jump_to_line(self, bufnr, entry)
          end,
        })
      end,
    }),
  }):find()
end

return M
