-- Plugins:
-- - telescope.nvim: https://github.com/nvim-telescope/telescope.nvim
--   Provides fuzzy finding for files, buffers, grep, diagnostics, and more.
-- - telescope-ui-select.nvim: https://github.com/nvim-telescope/telescope-ui-select.nvim
--   Replaces vim.ui.select with Telescope pickers.
-- - telescope-fzf-native.nvim: https://github.com/nvim-telescope/telescope-fzf-native.nvim
--   Adds native fzf sorting for Telescope.
-- - plenary.nvim: https://github.com/nvim-lua/plenary.nvim
--   Provides Lua utility functions required by Telescope.

local util = require("plugins.util")
local ui = require("core.ui")

-- build
util.build("telescope-fzf-native.nvim", function(data)
    vim.system({ "make" }, { cwd = data.path }, function(result)
        util.notify_build_error("telescope-fzf-native build failed", result)
    end)
end)

-- install
vim.pack.add({
    util.gh("nvim-lua/plenary.nvim"),
    util.gh("nvim-telescope/telescope-ui-select.nvim"),
    util.gh("nvim-telescope/telescope-fzf-native.nvim"),
    { src = util.gh("nvim-telescope/telescope.nvim"), version = "v0.2.1" },
})

-- setup
local builtin = require("telescope.builtin")
local actions = require("telescope.actions")
local borderchars = {
    prompt = ui.surface_border,
    results = ui.surface_border,
    preview = ui.surface_border,
}

require("telescope").setup({
    defaults = {
        initial_mode = "insert",
        mappings = {
            i = {
                ["<esc>"] = actions.close,
            },
        },
        sorting_strategy = "ascending",
        border = true,
        borderchars = borderchars,
        layout_config = {
            prompt_position = "top",
        },
    },
    extensions = {
        ["ui-select"] = {
            require("telescope.themes").get_dropdown({
                border = true,
                borderchars = borderchars,
            }),
        },
    },
})

require("telescope").load_extension("fzf")
require("telescope").load_extension("ui-select")

-- keymaps
vim.keymap.set("n", "g/", builtin.live_grep, { desc = "Global search (Live Grep)" })
vim.keymap.set("n", "g*", builtin.grep_string, { desc = "Search word under cursor" })

vim.keymap.set("n", "<leader>D", builtin.diagnostics, {
    desc = "Workspace diagnostics",
})

vim.keymap.set("n", "<leader>d", function()
    builtin.diagnostics({ bufnr = 0 })
end, {
    desc = "Buffer diagnostics",
})

vim.keymap.set("n", "<leader>b", function()
    builtin.buffers({
        sort_mru = true,
        select_current = true,
        show_all_buffers = true,
    })
end, {
    desc = "Buffers",
})

vim.keymap.set("v", "g/", function()
    local function get_visual_selection()
        vim.cmd('noau normal! "vy"')
        local text = vim.fn.getreg("v")
        vim.fn.setreg("v", {})
        return text
    end

    local selection = get_visual_selection()
    builtin.live_grep({ default_text = selection })
end, { desc = "Search selection in project" })
