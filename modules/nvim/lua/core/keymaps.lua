vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Filetree
vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle Filetree", silent = true })

-- File Finder
vim.keymap.set("n", "<leader>f", ":FFFind<CR>", { desc = "Toggle File Finder", silent = true })

-- Statusbar
local function toggle_status_bar()
  vim.opt.laststatus = vim.opt.laststatus:get() > 0 and 0 or 3
end
vim.keymap.set("n", "<leader>S", toggle_status_bar, { desc = "Toggle Statusline" })
