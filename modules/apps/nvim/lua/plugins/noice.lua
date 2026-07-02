return {
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        opts = {
            views = {
                hover = {
                    border = {
                        style = "rounded",
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
