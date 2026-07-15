-- Plugin: monodark.nvim
-- URL: https://github.com/blackgolyb/monodark.nvim
-- Description: Local dark colorscheme with transparent background support.

local util = require("plugins.util")
local monodark_dir = vim.fn.expand("~/nixos/monodark.nvim")

-- pre
if vim.uv.fs_stat(monodark_dir) then
    vim.opt.runtimepath:prepend(monodark_dir)
else
    -- install
    vim.pack.add({ util.gh("blackgolyb/monodark.nvim") })
end

-- setup
require("monodark").setup({
    transparent_background = true,
})
require("monodark").load()
