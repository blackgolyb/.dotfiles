function buffer_boundary()
    local n_lines = vim.api.nvim_buf_line_count(0)
    local last_line = vim.api.nvim_buf_get_lines(0, n_lines - 1, n_lines, true)[1]
    return {
        from = { line = 1, col = 1 },
        to = { line = n_lines, col = #last_line + 1 },
    }
end

function indent_boundary()
    local from_line = vim.fn.line('.')
    local indent = vim.fn.indent(from_line)

    local function get_boundary(dir)
        local cur = from_line
        local last = cur
        while true do
            cur = cur + dir
            if cur < 1 or cur > vim.fn.line('$') then break end
            if vim.fn.getline(cur):match('^%s*$') then
                last = cur
            elseif vim.fn.indent(cur) >= indent then
                last = cur
            else
                break
            end
        end
        return last
    end

    return {
        from = { line = get_boundary(-1), col = 1 },
        to   = { line = get_boundary(1), col = 10000 },
    }
end

return {
    {
        "nvim-mini/mini.ai",
        version = false,
        config = function()
            local ai = require("mini.ai")
            ai.setup({
                custom_textobjects = {
                    e = buffer_boundary,
                    i = indent_boundary,
                },
            })
        end,
    },
    { 'nvim-mini/mini.move', version = false, config = true },
    -- { 'nvim-mini/mini.surround', version = false, config = true },
    { 'nvim-mini/mini.pairs', version = false, config = true },
}
