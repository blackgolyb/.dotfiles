local ui = require("core.ui")

return {
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        opts = {
            views = {
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
            notify = {
                enabled = false,
            },
        },
        dependencies = {
            "MunifTanjim/nui.nvim",
        }
    },
}
