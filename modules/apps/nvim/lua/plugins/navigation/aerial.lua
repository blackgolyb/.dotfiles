-- Plugins:
-- - aerial.nvim: https://github.com/stevearc/aerial.nvim
--   Provides code outline and symbol navigation.
-- - nvim-treesitter: https://github.com/nvim-treesitter/nvim-treesitter
--   Provides Treesitter symbols used by Aerial.
-- - nvim-web-devicons: https://github.com/nvim-tree/nvim-web-devicons
--   Provides icons for outline entries.

local util = require("plugins.util")

-- install
vim.pack.add({
	util.gh("nvim-treesitter/nvim-treesitter"),
	util.gh("nvim-tree/nvim-web-devicons"),
	util.gh("stevearc/aerial.nvim"),
})

-- setup
require("aerial").setup({
	layout = {
		min_width = 30,
	},
	manage_folds = false,
})

require("telescope").load_extension("aerial")

-- keymaps
vim.keymap.set("n", "gs", "<cmd>Telescope aerial<CR>", { desc = "Search Symbols (Aerial)" })
