-- Plugins:
-- - vim-tpipeline: https://github.com/vimpostor/vim-tpipeline
--   Pushes the Neovim statusline into the tmux status bar.
-- - lualine.nvim: https://github.com/nvim-lualine/lualine.nvim
--   Provides the statusline data rendered by the tmux integration.

local util = require("plugins.util")

-- pre
require("core.tmux_lualine").setup()

function _G.tmux_lualine_statusline()
	return require("core.tmux_lualine").statusline()
end

vim.g.tpipeline_clearstl = 1
vim.g.tpipeline_statusline = "%!v:lua.tmux_lualine_statusline()"

-- install
vim.pack.add({
	util.gh("nvim-lualine/lualine.nvim"),
	util.gh("vimpostor/vim-tpipeline"),
})
