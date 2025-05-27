-- Create a ring buffer object
local RingBuffer = {}
RingBuffer.__index = RingBuffer

function RingBuffer.new(size)
  local self = setmetatable({}, RingBuffer)
  self.size = size   -- Maximum size of the buffer
  self.elements = {} -- Array to store elements
  self.current = 0   -- Current position pointer
  self.count = 0     -- Number of elements currently in the buffer
  return self
end

function RingBuffer:add(element)
  -- Increment count up to size
  self.count = math.min(self.count + 1, self.size)
  -- Move current position
  self.current = (self.current % self.size) + 1
  -- Add new element
  self.elements[self.current] = element
end

function RingBuffer:move_forward()
  if self.count == 0 then return nil end
  self.current = (self.current % self.count) + 1
  return self.elements[self.current]
end

function RingBuffer:move_backward()
  if self.count == 0 then return nil end
  self.current = ((self.current - 2 + self.count) % self.count) + 1
  return self.elements[self.current]
end

function RingBuffer:get_current()
  if self.count == 0 then return nil end
  return self.elements[self.current]
end

local MAX_JUMPS = 12

local M = {
  jumps = RingBuffer.new(MAX_JUMPS)
}

M.set_jump = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum, cnum = unpack(vim.api.nvim_win_get_cursor(0))
  M.jumps:add({ bufnr, lnum, cnum })
end

M.jump_back = function()
  local prev_pos = M.jumps:move_backward()
  if prev_pos then
    local bufnr, lnum, cnum = unpack(prev_pos)
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_set_current_buf(bufnr)
      vim.api.nvim_win_set_cursor(0, { lnum, cnum })
    end
  end
end

M.jump_forward = function()
  local next_pos = M.jumps:move_forward()
  if next_pos then
    local bufnr, lnum, cnum = unpack(next_pos)
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_set_current_buf(bufnr)
      vim.api.nvim_win_set_cursor(0, { lnum, cnum })
    end
  end
end

M.debug = function()
  for _, value in ipairs(M.jumps.elements) do
    vim.print(value)
  end
end

return M
