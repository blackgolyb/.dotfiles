-- Plugin: quarto-nvim
-- URL: https://github.com/quarto-dev/quarto-nvim
-- Description: LSP features and code running for markdown/quarto notebooks via otter.nvim.

local util = require("plugins.util")

vim.pack.add({
    util.gh("quarto-dev/quarto-nvim"),
    util.gh("jmbuhr/otter.nvim"),
})

require("quarto").setup({
    lspFeatures = {
        languages = { "python", "r", "rust" },
        chunks = "all",
        diagnostics = {
            enabled = true,
            triggers = { "BufWritePost" },
        },
        completion = {
            enabled = true,
        },
    },
    keymap = {
        hover = "H",
        definition = "gd",
        rename = "<leader>rn",
        references = "gr",
        format = "<leader>gf",
    },
    codeRunner = {
        enabled = true,
        default_method = "molten",
    },
})
