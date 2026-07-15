-- Plugins:
-- - lazygit.nvim: https://github.com/kdheepak/lazygit.nvim
--   Provides LazyGit commands and Neovim remote integration.
-- - plenary.nvim: https://github.com/nvim-lua/plenary.nvim
--   Provides Lua utility functions required by lazygit.nvim.

local util = require("plugins.util")

-- pre
local ui = require("core.ui")

if vim.v.servername == "" then
	vim.fn.serverstart()
end

vim.g.lazygit_use_neovim_remote = 1
vim.g.lazygit_floating_window_border_chars = ui.surface_border
vim.env.NVIM_LISTEN_ADDRESS = vim.v.servername
vim.env.GIT_EDITOR = "nvr --remote-wait-silent +'set bufhidden=wipe'"

-- install
vim.pack.add({
	util.gh("nvim-lua/plenary.nvim"),
	util.gh("kdheepak/lazygit.nvim"),
})

-- keymaps
vim.keymap.set("n", "<leader>g", "<cmd>LazyGit<cr>", { desc = "LazyGit" })
