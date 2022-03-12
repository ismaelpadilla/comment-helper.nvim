local ts_locals = require "nvim-treesitter.locals"
local ts_utils = require "nvim-treesitter.ts_utils"

local M = {}

-- get node coordinates in a printable format
M.GetCoords = function(node)
  local start_row, start_col = node:start()
  local end_row, end_col = node:end_()
  return "[" .. start_row .. ", " .. start_col .. "] - [" .. end_row .. ", " .. end_col .. "]"
end

-- get first node in current line, ignoring certain types
M.GetFirstInLine = function()
  -- types to ignore
  local ignored_types = { "block", "source" }

  -- get first node in current line
  -- we start from current node and go back and up
  local node_cur = ts_utils.get_node_at_cursor()
  local row, _ = node_cur:start()
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
  if row+1 ~= cursor_row then
    print("found nothing")
    return nil
  end

  local node_prev = nil
  while true do
    node_prev = node_cur
    node_cur = ts_utils.get_previous_node(node_cur, false, false)

    -- no parent? try to go up
    if node_cur == nil then
      node_cur = node_prev:parent()
      -- parent nil? then we are at root
      if node_cur == nil then break end
    end

    -- did we overshoot while going back?
    -- If so, the previous node is the one we want
    local row_cur, _ = node_cur:start()
    local row_prev, _ = node_prev:start()
    if row_cur ~= row_prev or vim.tbl_contains(ignored_types, node_cur:type()) then
      break
    end
  end
  print(node_prev:type())
  return node_prev
end

return M
