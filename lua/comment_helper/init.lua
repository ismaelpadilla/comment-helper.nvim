local ts_utils = require "nvim-treesitter.ts_utils"

local M = {}

M._support_table = {}
-- support table has the following shape:
-- M._support_table = {
--   [language] = { { node_type = { fn = ..., ignored_types = ... } }
-- }

local config = {
  -- Enable luasnip snippets.
  luasnip_enabled = false,

  -- If luasnip isn't supported and we receive a snippet as a comment,
  -- attempt to turn it into text and insert it.
  snippets_to_text = false,

  -- Function to call after a comment is placed.
  post_hook = nil,
}

--- get options table to pass on to other plugins
local get_options = function()
  return { luasnip_enabled = config.luasnip_enabled }
end

M.setup = function(cfg)
  config = vim.tbl_deep_extend("force", config, cfg)
end

-- get node coordinates in a printable format
M.GetCoords = function(node)
  local start_row, start_col = node:start()
  local end_row, end_col = node:end_()
  return "[" .. start_row .. ", " .. start_col .. "] - [" .. end_row .. ", " .. end_col .. "]"
end

-- get first treesitter node in current line, ignoring certain types
M.GetFirstNodeInLine = function(ignored_types)
  -- get first node in current line
  -- we start from current node and go back and up
  local node_cur = ts_utils.get_node_at_cursor()
  local row, _ = node_cur:start()
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
  if row + 1 ~= cursor_row then
    print "found nothing"
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
      if node_cur == nil then
        break
      end
    end

    -- did we overshoot while going back?
    -- If so, the previous node is the one we want
    local row_cur, _ = node_cur:start()
    local row_prev, _ = node_prev:start()
    if row_cur ~= row_prev or vim.tbl_contains(ignored_types, node_cur:type()) then
      break
    end
  end
  print("found " .. node_prev:type())
  return node_prev
end

M.GetLineComment = function()
  local filetype = vim.api.nvim_buf_get_option(0, "filetype")

  if M._support_table[filetype] == nil then
    print "filetype not supported"
    return
  end

  local ignored = M._support_table[filetype].ignored_types or {}
  local node = M.GetFirstNodeInLine(ignored)
  local type = node:type()

  if M._support_table[filetype][type] == nil then
    print "node type not suported"
    return
  end

  return M._support_table[filetype][type].fn(node, get_options())
end

M.WriteLineComment = function(comment, position)
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1]

  local line
  if position == "above" then
    line = cursor_row - 1
  elseif position == "below" then
    line = cursor_row
  end

  -- indent every line
  local indent_amount = vim.fn.indent(cursor_row)
  local indent_text = string.rep(" ", indent_amount)

  comment = vim.tbl_map(function(c)
    return indent_text .. c
  end, comment)

  vim.api.nvim_buf_set_lines(0, line, line, true, comment)
end

M.TriggerSnippet = function(snippet, position)
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
  local line

  if position == "above" then
    line = cursor_row - 1
  elseif position == "below" then
    line = cursor_row
  end

  local ls = require "luasnip"

  local indent_amount = vim.fn.indent(cursor_row)
  local indent_text = string.rep(" ", indent_amount)

  -- create blank line above
  vim.api.nvim_buf_set_lines(0, line, line, true, { indent_text })

  ls.snip_expand(snippet, { pos = { line, indent_amount } })
end

--- Turn a snippet into a list of Lines.
local snippet_to_text = function(snippet)
  return snippet:get_static_text()
end

M.CommentLine = function()
  local comment = M.GetLineComment()
  if comment == nil then
    return
  end

  -- place above by default
  comment.position = comment.position or "above"
  if comment.type == "text" then
    M.WriteLineComment(comment.result, comment.position)
  elseif comment.type == "luasnip" then
    if config.luasnip_enabled then
      M.TriggerSnippet(comment.result, comment.position)
    elseif config.snippets_to_text then
      local snippet_as_text = snippet_to_text(comment.result)
      M.WriteLineComment(snippet_as_text, comment.position)
    end
  end

  if config.post_hook ~= nil then
    config.post_hook()
  end
end

--- Add comment support for a specific node type of a specifi comment.
-- @param lang The language to add support for.
-- @param node_type The node type to add support for.
-- @param fn The function to call to obtain a comment for a specific node.
-- @param ignored_types when attempting to comment a line, ignored_types will be ignored.
M.add = function(lang, node_type, fn, ignored_types)
  if M._support_table[lang] == nil then
    M._support_table[lang] = { [node_type] = { fn = fn, ignored_types = ignored_types } }
  else
    M._support_table[lang][node_type] = { fn = fn, ignored_types = ignored_types }
  end
end

return M
