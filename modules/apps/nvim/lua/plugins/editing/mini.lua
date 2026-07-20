-- Plugins:
-- - mini.ai: https://github.com/nvim-mini/mini.ai
--   Provides configurable textobjects.
-- - mini.move: https://github.com/nvim-mini/mini.move
--   Moves lines and selections.
-- - mini.surround: https://github.com/nvim-mini/mini.surround
--   Adds, deletes, and replaces surrounding characters.
-- - mini.pairs: https://github.com/nvim-mini/mini.pairs
--   Inserts matching pairs while typing.
-- - nvim-treesitter-textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
--   Provides Treesitter textobject queries used by mini.ai.

local util = require("plugins.util")

-- install
vim.pack.add({
    util.gh("nvim-treesitter/nvim-treesitter-textobjects"),
    util.gh("nvim-mini/mini.ai"),
    util.gh("nvim-mini/mini.move"),
    util.gh("nvim-mini/mini.surround"),
    util.gh("nvim-mini/mini.pairs"),
})

function buffer_boundary()
    local n_lines = vim.api.nvim_buf_line_count(0)
    local last_line = vim.api.nvim_buf_get_lines(0, n_lines - 1, n_lines, true)[1]
    return {
        from = { line = 1, col = 1 },
        to = { line = n_lines, col = #last_line + 1 },
    }
end

function indent_boundary()
    local from_line = vim.fn.line(".")
    local indent = vim.fn.indent(from_line)

    local function get_boundary(dir)
        local cur = from_line
        local last = cur
        while true do
            cur = cur + dir
            if cur < 1 or cur > vim.fn.line("$") then
                break
            end
            if vim.fn.getline(cur):match("^%s*$") then
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
        to = { line = get_boundary(1), col = 10000 },
    }
end

-- setup
local ai = require("mini.ai")
ai.setup({
    custom_textobjects = {
        e = buffer_boundary,
        i = indent_boundary,

        b = ai.gen_spec.pair("(", ")", { type = "balanced" }),
        B = ai.gen_spec.pair("{", "}", { type = "balanced" }),

        c = ai.gen_spec.treesitter({
            a = "@class.outer",
            i = "@class.inner",
        }),
        f = ai.gen_spec.treesitter({
            a = "@function.outer",
            i = "@function.inner",
        }),
        k = ai.gen_spec.treesitter({
            a = "@comment.outer",
            i = "@comment.inner",
        }),
    },
})

require("mini.move").setup()

require("mini.surround").setup({
    mappings = {
        add = "Sa",
        delete = "Sd",
        find = "Sf",
        find_left = "SF",
        highlight = "Sh",
        replace = "Sr",
    },
})

require("mini.pairs").setup({
    modes = {
        insert = true,
        command = false,
        terminal = false,
    },

    mappings = {
        ["("] = {
            action = "open",
            pair = "()",
            neigh_pattern = "[^\\][^%(]",
        },
        ["["] = {
            action = "open",
            pair = "[]",
            neigh_pattern = "[^\\][^%[]",
        },
        ["{"] = {
            action = "open",
            pair = "{}",
            neigh_pattern = "[^\\][^%{]",
        },

        [")"] = { action = "close", pair = "()" },
        ["]"] = { action = "close", pair = "[]" },
        ["}"] = { action = "close", pair = "{}" },

        ['"'] = {
            action = "closeopen",
            pair = '""',
            neigh_pattern = "[^\\].",
            register = { cr = false },
        },
        ["'"] = {
            action = "closeopen",
            pair = "''",
            neigh_pattern = "[^%a\\].",
            register = { cr = false },
        },
        ["`"] = {
            action = "closeopen",
            pair = "``",
            neigh_pattern = "[^\\].",
            register = { cr = false },
        },
    },
})
