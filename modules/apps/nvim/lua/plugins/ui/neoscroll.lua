-- Plugin: neoscroll.nvim
-- URL: https://github.com/karb94/neoscroll.nvim
-- Description: Adds smooth animated scrolling for window movement commands.

local util = require("plugins.util")

-- install
vim.pack.add({ util.gh("karb94/neoscroll.nvim") })

-- setup
require("neoscroll").setup({
	duration_multiplier = 0.5,
})
