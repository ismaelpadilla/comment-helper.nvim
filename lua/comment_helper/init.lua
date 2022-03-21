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

local rustFunctionDescription = function(node)
    local comment = { "/// function description" }
    local children = ts_utils.get_named_children(node)
    local parameters = nil
    for _, v in ipairs(children) do
        if v:type() == "parameters" then
            parameters = ts_utils.get_named_children(v)
        end
    end

    if not next(parameters) then return { result = comment, type = "text" } end

    table.insert(comment, "///")
    table.insert(comment, "/// # Arguments")
    table.insert(comment, "///")

    for _, v in ipairs(parameters) do
        for _, v2 in ipairs(ts_utils.get_named_children(v)) do
            if v2:type() == "identifier" then
                local c = "/// * `" .. ts_utils.get_node_text(v2)[1] .. "` - "
                table.insert(comment, c)
            end
        end
    end

    return { result = comment, type = "text" }
end

local rustFunctionDescriptionSnippet = function(node)
    local ls = require('luasnip')
    local s = ls.s
    local fmt = require("luasnip.extras.fmt").fmt
    local i = ls.insert_node
    local t = ls.t
    local rep = require("luasnip.extras").rep

    local snippet_text = { "/// function description" }
    local snippet_params = {}
    local param_count = 0

    local children = ts_utils.get_named_children(node)
    local parameters = nil
    for _, v in ipairs(children) do
        if v:type() == "parameters" then
            parameters = ts_utils.get_named_children(v)
        end
    end

    if not next(parameters) then
        snippet_text = table.concat(snippet_text, "\n")
        local snippet = s("", { t(snippet_text) })
        return { result = snippet, type = "luasnip" }
        -- return snippet_text 
    end

    table.insert(snippet_text, "///")
    table.insert(snippet_text, "/// # Arguments")
    table.insert(snippet_text, "///")

    for _, v in ipairs(parameters) do
        for _, v2 in ipairs(ts_utils.get_named_children(v)) do
            if v2:type() == "identifier" then
                local c = "/// * `" .. ts_utils.get_node_text(v2)[1] .. "` - {}"
                table.insert(snippet_text, c)
                param_count = param_count + 1
                table.insert(snippet_params, i(param_count))
            end
        end
    end

    snippet_text = table.concat(snippet_text, "\n")

    local snippet = s("", fmt(snippet_text, snippet_params))

    return { result = snippet, type = "luasnip" }
end

local testDict = {
    rust = {
        function_item = rustFunctionDescription
    }
}

M.GetLineComment = function()
    local filetype = vim.api.nvim_buf_get_option(0, 'filetype')

    if testDict[filetype] == nil then
        print("filetype not supported")
        return
    end

    local ignored_types = { "block", "source" }
    local node = M.GetFirstInLine(ignored_types)
    local type = node:type()

    if testDict[filetype][type] == nil then
        print("node type not suported")
        return
    end

    return testDict[filetype][type](node)
end

M.WriteLineComment = function(comment)
    local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
    local line = cursor_row - 1
    vim.api.nvim_buf_set_lines(0, line, line, true, comment)
end

M.TriggerSnippet = function(snippet)
    local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
    local line = cursor_row - 1

    local ls = require('luasnip')

    -- create blank line above
    vim.api.nvim_buf_set_lines(0, line, line, true, { "" })

    ls.snip_expand(snippet, { pos = { line, 0 } })
end

M.CommentLine = function()
    local comment = M.GetLineComment()
    if comment ~= nil and comment.type == "text" then
        M.WriteLineComment(comment.result)
    end
end

M.SnipLine = function()
    local ignored_types = { "block", "source" }
    local node = M.GetFirstInLine(ignored_types)
    local snippet = rustFunctionDescriptionSnippet(node)
    if snippet ~= nil and snippet.type == "luasnip" then
        M.TriggerSnippet(snippet.result)
    end
end

vim.api.nvim_set_keymap('n', '<leader>cl', '<cmd> lua require("comment_helper").CommentLine()<CR><cmd>w<CR>', {})
vim.api.nvim_set_keymap('n', '<leader>sl', '<cmd> lua require("comment_helper").SnipLine()<CR><cmd>w<CR>', {})

return M
