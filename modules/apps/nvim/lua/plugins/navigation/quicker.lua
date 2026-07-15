-- Plugin: quicker.nvim
-- URL: https://github.com/stevearc/quicker.nvim
-- Description: Improves quickfix and loclist UI with editing support.

local util = require("plugins.util")

-- install
vim.pack.add({ util.gh("stevearc/quicker.nvim") })

-- setup
require("quicker").setup({})

-- keymaps
vim.keymap.set("n", "<leader>q", function()
	require("quicker").toggle()
end, { desc = "Toggle quickfix" })

vim.keymap.set("n", "<leader>l", function()
	require("quicker").toggle({ loclist = true })
end, { desc = "Toggle loclist" })
