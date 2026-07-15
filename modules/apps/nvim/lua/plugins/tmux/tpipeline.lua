-- Plugins:
-- - vim-tpipeline: https://github.com/vimpostor/vim-tpipeline
--   Pushes the Neovim statusline into the tmux status bar.
-- - lualine.nvim: https://github.com/nvim-lualine/lualine.nvim
--   Provides the statusline data rendered by the tmux integration.

local util = require("plugins.util")
local status_line = require("plugins.tmux.status_line")

-- pre
status_line.setup()

function _G.tmux_statusline()
    return require("plugins.tmux.status_line").statusline()
end

vim.g.tpipeline_clearstl = 1
vim.g.tpipeline_statusline = "%!v:lua.tmux_statusline()"

-- install
vim.pack.add({
    util.gh("nvim-lualine/lualine.nvim"),
    util.gh("vimpostor/vim-tpipeline"),
})
