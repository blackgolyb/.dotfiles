-- Plugin: jupytext.nvim
-- URL: https://github.com/GCBallesteros/jupytext.nvim
-- Description: Convert .ipynb notebooks to plaintext markdown and back.

local util = require("plugins.util")

vim.pack.add({ util.gh("GCBallesteros/jupytext.nvim") })

require("jupytext").setup({
    style = "markdown",
    output_extension = "md",
    force_ft = "markdown",
})
