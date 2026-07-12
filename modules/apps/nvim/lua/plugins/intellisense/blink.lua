-- Autocompletion engine with fuzzy matching
local ui = require("core.ui")

return {
    {
        'saghen/blink.cmp',
        branch = 'v1',
        version = '*',
        opts = {
            keymap = { preset = 'default' },

            appearance = {
                use_nvim_cmp_as_default = false,
                nerd_font_variant = 'mono'
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
        },
    },
}
