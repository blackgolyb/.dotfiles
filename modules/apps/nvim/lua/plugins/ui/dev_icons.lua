-- Plugin: nvim-web-devicons
-- URL: https://github.com/nvim-tree/nvim-web-devicons
-- Description: Provides filetype and file icons for UI plugins.

local util = require("plugins.util")

-- install
vim.pack.add({ util.gh("nvim-tree/nvim-web-devicons") })

-- setup
require("nvim-web-devicons").setup({
	color_icons = false,
	default = true,
})
