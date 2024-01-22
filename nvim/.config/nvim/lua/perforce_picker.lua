local M = {}

M.opened = function(opts)
  opts = opts or {}

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local make_entry = require("telescope.make_entry")

  local find_command = { "p4", "-F", "%clientFile%", "fstat", "-Ro", "..." }
  opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)

  pickers.new(opts, {
    prompt_title = "Perforce Opened",
    -- finder = finders.new_table { results = results },
    finder = finders.new_oneshot_job(find_command, opts),
    sorter = conf.generic_sorter(opts)
  }):find()
end

return M
