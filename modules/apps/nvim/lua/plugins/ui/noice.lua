-- Plugins:
-- - noice.nvim: https://github.com/folke/noice.nvim
--   Enhances messages, command-line UI, notifications, and LSP popups.
-- - nui.nvim: https://github.com/MunifTanjim/nui.nvim
--   Provides reusable Neovim UI primitives used by noice.nvim.

local util = require("plugins.util")
local ui = require("core.ui")

-- install
vim.pack.add({
    util.gh("MunifTanjim/nui.nvim"),
    util.gh("folke/noice.nvim"),
})

-- setup
require("noice").setup({
    messages = {
        enabled = true,
        view = "mini",
        view_error = "notify",
        view_warn = "notify",
        view_history = "messages",
        view_search = false,
    },
    notify = {
        enabled = true,
        view = "notify",
    },
    views = {
        mini = {
            timeout = 1800,
        },
        notify = {
            timeout = 3500,
            merge = false,
            replace = false,
        },
        messages = {
            enter = true,
            size = "25%",
        },
        cmdline_popup = {
            border = {
                style = ui.surface_border,
            },
        },
        cmdline_input = {
            border = {
                style = ui.surface_border,
            },
        },
        popup = {
            border = {
                style = ui.surface_border,
            },
        },
        confirm = {
            border = {
                style = ui.surface_border,
            },
        },
        popupmenu = {
            border = {
                style = ui.surface_border,
                padding = { 0, 1 },
            },
        },
        cmdline_popupmenu = {
            border = {
                style = ui.surface_border,
                padding = { 0, 1 },
            },
        },
        hover = {
            border = {
                style = ui.surface_border,
            },
        },
    },
    lsp = {
        signature = {
            enabled = false,
        },
        hover = {
            enabled = false,
        },
    },
})
