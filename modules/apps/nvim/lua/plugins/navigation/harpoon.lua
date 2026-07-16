-- Plugins:
-- - harpoon: https://github.com/ThePrimeagen/harpoon
--   Provides quick file bookmarking and jump lists.
-- - plenary.nvim: https://github.com/nvim-lua/plenary.nvim
--   Provides Lua utility functions required by Harpoon.

local util = require("plugins.util")

-- install
vim.pack.add({
    util.gh("nvim-lua/plenary.nvim"),
    { src = util.gh("ThePrimeagen/harpoon"), version = "harpoon2" },
})

-- setup
local harpoon = require("harpoon")
harpoon:setup({
    settings = {
        save_on_toggle = true,
        sync_on_ui_close = true,
    },
})

-- keymaps
vim.keymap.set("n", "<leader>t", function()
    harpoon.ui:toggle_quick_menu(harpoon:list(), { title_pos = "center" })
end, { desc = "Harpoon Menu" })

vim.keymap.set("n", "<leader>a", function()
    harpoon:list():add()
end, { desc = "Harpoon Add File" })

vim.keymap.set("n", "<leader>d", function()
    harpoon:list():remove()
end, { desc = "Harpoon Remove File" })

vim.keymap.set("n", "<leader>C", function()
    require("harpoon"):list():clear()
end, { desc = "Harpoon Clear List" })

vim.keymap.set("n", "<C-M-f>", function()
    harpoon:list():select(1)
end)
vim.keymap.set("n", "<C-M-d>", function()
    harpoon:list():select(2)
end)
vim.keymap.set("n", "<C-M-s>", function()
    harpoon:list():select(3)
end)
vim.keymap.set("n", "<C-M-a>", function()
    harpoon:list():select(4)
end)
