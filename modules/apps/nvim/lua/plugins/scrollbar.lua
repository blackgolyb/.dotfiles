return {
    {
        "petertriho/nvim-scrollbar",
        event = "BufReadPost",
        opts = {
            handle = {
                blend = 0,
                hide_if_all_visible = true,
            },
            marks = {
                Cursor = { text = "-", priority = 0 },
                Search = { text = { "-", "=" }, priority = 1 },
                Error = { text = { "-", "=" }, priority = 2 },
                Warn = { text = { "-", "=" }, priority = 3 },
                Info = { text = { "-", "=" }, priority = 4 },
                Hint = { text = { "-", "=" }, priority = 5 },
                Misc = { text = { "-", "=" }, priority = 6 },
            },
            excluded_buftypes = {
                "terminal",
            },
            excluded_filetypes = {
                "blink-cmp-menu",
                "cmp_docs",
                "cmp_menu",
                "noice",
                "prompt",
                "TelescopePrompt",
                "opencode_prompt",
                "neo-tree",
            },
            handlers = {
                cursor = false,
                diagnostic = true,
                gitsigns = true,
                handle = true,
                search = true,
            },
        },
    },
    {
        "kevinhwang91/nvim-hlslens",
        event = "BufReadPost",
        dependencies = { "petertriho/nvim-scrollbar" },
        config = function()
            require("hlslens").setup()
            require("scrollbar.handlers.search").setup({
                override_lens = function() end,
            })
        end,
    },
}
