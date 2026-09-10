-- Plugin: image.nvim
-- URL: https://github.com/3rd/image.nvim
-- Description: Image rendering in Neovim for molten-nvim outputs.

local util = require("plugins.util")

vim.pack.add({
    { src = util.gh("3rd/image.nvim"), version = "v1.1.0" },
})

local image = require("image")
local ok, err = pcall(image.setup, {
    backend = "kitty",
    integrations = {},
    max_width = 100,
    max_height = 12,
    max_height_window_percentage = math.huge,
    max_width_window_percentage = math.huge,
    window_overlap_clear_enabled = true,
    window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
})
if not ok then
    vim.notify("image.nvim setup failed: " .. tostring(err), vim.log.levels.WARN)
end
