-- Text objects, surround, move, pairs, toggle, split/join
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
        'rmagatti/alternate-toggler',
        opts = {
            alternates = {
                { 'true', 'false' },
                { 'True', 'False' },
                { 'TRUE', 'FALSE' },
                { 'Yes', 'No' },
                { 'YES', 'NO' },
                { '1', '0' },
                { '<', '>' },
                { '>=', '<=' },
                { '+', '-' },
                { '===', '!==' },
                { '==', '!=' },
                { '&&', '||' },
                { 'and', 'or' },
                { 'public', 'private', 'protected' },
            },
        },
        config = function(_, opts)
            require('alternate-toggler').setup(opts)
        end,
    },
    {
        'Wansmer/treesj',
        keys = {
            {
                '<leader>m',
                function()
                    local changedtick = vim.b.changedtick
                    vim.cmd.ToggleAlternate()

                    if vim.b.changedtick ~= changedtick then
                        return
                    end

                    require('treesj').toggle()
                end,
                desc = 'Toggle alternate or split/join',
            },
        },
        config = function()
            require('treesj').setup({
                use_default_keymaps = false,
            })
        end,
    },
    {
        "nvim-mini/mini.ai",
        version = false,
        dependencies = {
            "nvim-treesitter/nvim-treesitter-textobjects",
        },
        config = function()
            local ai = require("mini.ai")
            ai.setup({
                custom_textobjects = {
                    e = buffer_boundary,
                    i = indent_boundary,
                    b = ai.gen_spec.pair("(", ")"),
                    B = ai.gen_spec.pair("{", "}"),
                    f = ai.gen_spec.treesitter({
                        a = "@function.outer",
                        i = "@function.inner",
                    }),
                },
            })
        end,
    },
    { 'nvim-mini/mini.move', version = false, config = true },
    {
        'nvim-mini/mini.surround',
        version = false,
        config = function()
            local surround = require("mini.surround")
            surround.setup({
                  mappings = {
                    add = 'Sa',
                    delete = 'Sd',
                    find = 'Sf',
                    find_left = 'SF',
                    highlight = 'Sh',
                    replace = 'Sr',
                },
            })
        end,
    },
    { 'nvim-mini/mini.pairs', version = false, config = true },
}
