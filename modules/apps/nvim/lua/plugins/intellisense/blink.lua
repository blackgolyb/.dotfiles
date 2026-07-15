-- Plugin: blink.cmp
-- URL: https://github.com/saghen/blink.cmp
-- Description: Provides autocompletion with fuzzy matching and LSP capabilities.

local util = require("plugins.util")
local ui = require("core.ui")

-- install
vim.pack.add({
    { src = util.gh("saghen/blink.cmp"), version = "v1" },
})

-- setup
require("blink.cmp").setup({
    keymap = { preset = "default" },
    appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = "mono",
    },
    completion = {
        menu = {
            border = ui.surface_border,
        },
        documentation = {
            window = {
                border = ui.surface_border,
            },
        },
    },
    signature = {
        window = {
            border = ui.surface_border,
        },
    },
})
