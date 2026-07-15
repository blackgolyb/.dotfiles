-- Plugins:
-- - oil.nvim: https://github.com/stevearc/oil.nvim
--   Provides a buffer-based file explorer and file operation UI.
-- - nvim-web-devicons: https://github.com/nvim-tree/nvim-web-devicons
--   Provides file icons for Oil columns.

local util = require("plugins.util")
local ui = require("core.ui")

-- pre
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- install
vim.pack.add({
    util.gh("nvim-tree/nvim-web-devicons"),
    util.gh("stevearc/oil.nvim"),
})

-- setup
require("oil").setup({
    default_file_explorer = true,
    columns = {
        "icon",
    },
    keymaps = {
        -- ["<Esc>"] = "actions.close",
        ["q"] = "actions.close",
    },
    view_options = {
        show_hidden = true,
    },
    float = {
        border = ui.surface_border,
    },
    confirmation = {
        border = ui.surface_border,
    },
    progress = {
        border = ui.surface_border,
        minimized_border = ui.surface_border,
    },
    ssh = {
        border = ui.surface_border,
    },
    keymaps_help = {
        border = ui.surface_border,
    },
})

-- keymaps
vim.keymap.set("n", "<leader>e", "<cmd>Oil --float<cr>", {
    desc = "Open oil at the current file",
})
