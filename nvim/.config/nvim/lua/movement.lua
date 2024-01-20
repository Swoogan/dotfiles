local utils = require('utils')

local M = {

}

M.paragraph_down = function()
  local lnum, cnum = unpack(vim.api.nvim_win_get_cursor(0))
  local bufnr = vim.api.nvim_get_current_buf()
  if not utils.is_empty(bufnr, lnum) then
    lnum = utils.find_next_empty(bufnr, 1, lnum)
    if lnum == -1 then
      return
    end
  end
  lnum = utils.find_next_not_empty(bufnr, 1, lnum)
  if lnum > -1 then
    vim.api.nvim_win_set_cursor(0, { lnum, cnum })
  end
end

M.paragraph_up = function()
  local winnr = vim.api.nvim_get_current_win()
  local lnum, cnum = unpack(vim.api.nvim_win_get_cursor(winnr))
  local bufnr = vim.api.nvim_get_current_buf()
  if not utils.is_empty(bufnr, lnum) then
    lnum = utils.find_next_empty(bufnr, -1, lnum)
    if lnum == -1 then
      return
    end
  end
  lnum = utils.find_next_not_empty(bufnr, -1, lnum)
  if lnum == -1 then
    return
  end
  lnum = utils.find_next_empty(bufnr, -1, lnum)
  if lnum == -1 or lnum > 0 then
    vim.api.nvim_win_set_cursor(winnr, { lnum + 1, cnum })
  end
end

return M
