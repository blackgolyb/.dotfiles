-- Plugin: nvim-highlight-colors
-- URL: https://github.com/brenoprata10/nvim-highlight-colors
-- Description: Renders inline color previews for color values.

local util = require("plugins.util")

-- install
vim.pack.add({ util.gh("brenoprata10/nvim-highlight-colors") })

-- setup
require("nvim-highlight-colors").setup({
	render = "virtual",
	virtual_symbol = "",
})
