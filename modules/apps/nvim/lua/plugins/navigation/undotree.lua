-- Plugins:
-- - undotree: https://github.com/mbbill/undotree
--   Provides a visual undo/redo history tree, integrated as a sidebar.

local util = require("plugins.util")

-- install
vim.pack.add({
    util.gh("mbbill/undotree"),
})

-- setup
vim.g.undotree_WindowLayout = 3
vim.g.undotree_SplitWidth = 36
vim.g.undotree_DiffpanelHeight = 10
vim.g.undotree_SetFocusWhenToggle = 1

-- sidebar integration
_G.sidebar_on_open("undotree", function()
    vim.cmd("UndotreeShow")
end)

_G.sidebar_on_focus("undotree", function()
    vim.cmd("UndotreeFocus")
end)

_G.sidebar_on_close("undotree", function()
    vim.cmd("UndotreeHide")
end)

-- Keep the sidebar state in sync when the undotree window closes through
-- any path (e.g. the builtin "q" mapping calling UndotreeToggle).
vim.api.nvim_create_autocmd("BufWinLeave", {
    desc = "Sync sidebar state when the undotree window closes",
    callback = function(ev)
        if vim.bo[ev.buf].filetype ~= "undotree" then
            return
        end
        if _G.sidebar_manager and _G.sidebar_manager.current == "undotree" then
            _G.sidebar_manager.current = "none"
        end
    end,
})

-- keymaps
vim.keymap.set("n", "<leader>u", function()
    _G.sidebar("undotree")
end, { desc = "Toggle Undotree sidebar", silent = true })
