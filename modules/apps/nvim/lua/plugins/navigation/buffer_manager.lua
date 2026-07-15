-- Plugins:
-- - local buffer manager: local core.buffers module
--   Provides an editable buffer manager backed by local configuration code.
-- - nvim-web-devicons: https://github.com/nvim-tree/nvim-web-devicons
--   Provides file icons for buffer entries.

local util = require("plugins.util")

-- install
vim.pack.add({ util.gh("nvim-tree/nvim-web-devicons") })

-- setup
require("core.buffers").setup({
	order = "lastused",
	close_modified = "confirm",
})

vim.api.nvim_create_user_command("Buffers", function()
	require("core.buffers").open()
end, { desc = "Open editable buffer manager" })

vim.api.nvim_create_user_command("BuffersFloat", function()
	require("core.buffers").open_float()
end, { desc = "Open editable buffer manager in a float" })

vim.api.nvim_create_user_command("BuffersCloseUnmodified", function()
	require("core.buffers").close_unmodified_except_current()
end, { desc = "Close unmodified buffers except current" })

-- keymaps
vim.keymap.set("n", "<leader>B", function()
	require("core.buffers").toggle_float()
end, { desc = "Editable buffers" })
