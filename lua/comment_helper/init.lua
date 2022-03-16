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
M.GetFirstInLine = function(ignored_types)
    -- types to ignore
    local ignored_types = { "block", "source" }

    -- get first node in current line
    -- we start from current node and go back and up
    local node_cur = ts_utils.get_node_at_cursor()
    local row, _ = node_cur:start()
    local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
    if row + 1 ~= cursor_row then
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
    print("found " .. node_prev:type())
    return node_prev
end

local testDict = {
    go = {
        function_declaration = function(node) return "result: " .. node:type() end
    }
}

M.GetLineComment = function()
    local filetype = vim.api.nvim_buf_get_option(0, 'filetype')
    -- local filetype = "asdasd"

    local ignored_types = { "block", "source" }
    local node = M.GetFirstInLine(ignored_types)
    local type = node:type()

    if testDict[filetype] == nil then
        print("filetype not supported")
        return
    end
    if testDict[filetype][type] == nil then
        print("node type not suported")
        return
    end

    print(testDict[filetype][type](node))
end

M.WriteLineComment = function()
    local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
    local line = cursor_row - 1
    vim.api.nvim_buf_set_lines(0, line, line, true, { "test" })
end


return M
