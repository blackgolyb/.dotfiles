-- Plugins:
-- - alternate-toggler: https://github.com/rmagatti/alternate-toggler
--   Toggles common alternates under cursor, such as true/false or ==/!=.
-- - treesj: https://github.com/Wansmer/treesj
--   Splits and joins Treesitter-aware syntax nodes.

local util = require("plugins.util")

-- install
vim.pack.add({
	util.gh("rmagatti/alternate-toggler"),
	util.gh("Wansmer/treesj"),
})

-- setup
require("alternate-toggler").setup({
	alternates = {
		{ "true", "false" },
		{ "True", "False" },
		{ "TRUE", "FALSE" },
		{ "Yes", "No" },
		{ "YES", "NO" },
		{ "1", "0" },
		{ "<", ">" },
		{ ">=", "<=" },
		{ "+", "-" },
		{ "===", "!==" },
		{ "==", "!=" },
		{ "&&", "||" },
		{ "and", "or" },
		{ "public", "private", "protected" },
	},
})

require("treesj").setup({
	use_default_keymaps = false,
})

-- keymaps
vim.keymap.set("n", "<leader>m", function()
	local changedtick = vim.b.changedtick
	vim.cmd.ToggleAlternate()

	if vim.b.changedtick ~= changedtick then
		return
	end

	require("treesj").toggle()
end, { desc = "Toggle alternate or split/join" })
