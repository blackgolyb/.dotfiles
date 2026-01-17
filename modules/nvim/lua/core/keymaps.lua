vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Filetree
vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle Explorer", silent = true })
