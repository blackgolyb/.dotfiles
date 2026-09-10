vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

vim.keymap.set("n", "Q", "<nop>")

-- Center view after scroll up/down
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Center view after search next/prev
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Keep indentation on an empty line created with `o`/`O` (e.g. `o<Esc>`).
-- `<Space><BS>` prevents Vim from stripping the auto-indent.
vim.keymap.set("n", "o", "o<Space><BS>", { remap = false })
vim.keymap.set("n", "O", "O<Space><BS>", { remap = false })

vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste over selection" })
vim.keymap.set("t", "<C-g>", [[<C-\><C-n>]], {
    desc = "Exit terminal mode",
})

vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move to left window" })
vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move to top window" })
vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move to right window" })

-- Statusbar
local function toggle_status_bar()
    vim.opt.laststatus = vim.opt.laststatus:get() > 0 and 0 or 3
end
vim.keymap.set("n", "<leader>s", toggle_status_bar, { desc = "Toggle Statusline" })

-- Commands
local cabbrev = function(expanded, original)
    vim.cmd("cnoreabbrev " .. expanded .. " " .. original)
end

cabbrev("W", "w")
cabbrev("Q", "q")
cabbrev("Wq", "wq")
cabbrev("WQ", "wq")
cabbrev("Wa", "wa")
cabbrev("Qa", "qa")
