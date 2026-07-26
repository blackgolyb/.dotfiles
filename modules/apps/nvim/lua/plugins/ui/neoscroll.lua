-- Plugin: neoscroll.nvim
-- URL: https://github.com/karb94/neoscroll.nvim
-- Description: Adds smooth animated scrolling for window movement commands.

local util = require("plugins.util")

-- install
vim.pack.add({ util.gh("karb94/neoscroll.nvim") })

-- setup
local neoscroll = require("neoscroll")
local config = {
    neoscroll = {
        duration_multiplier = 0.5,
    },
    mouse = {
        duration = 50,
        lines = 3,
    },
}

neoscroll.setup(config.neoscroll)

local function mouse_scroll(lines)
    local winid = vim.fn.getmousepos().winid
    if winid == 0 or not vim.api.nvim_win_is_valid(winid) then
        winid = 0
    end

    neoscroll.scroll(lines, {
        duration = config.mouse.duration,
        move_cursor = false,
        winid = winid,
    })
end

vim.keymap.set({ "n", "x", "i" }, "<ScrollWheelUp>", function()
    mouse_scroll(-config.mouse.lines)
end, { desc = "Smooth scroll up" })

vim.keymap.set({ "n", "x", "i" }, "<ScrollWheelDown>", function()
    mouse_scroll(config.mouse.lines)
end, { desc = "Smooth scroll down" })
