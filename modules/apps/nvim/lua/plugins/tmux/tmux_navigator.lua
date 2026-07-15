-- Plugin: vim-tmux-navigator
-- URL: https://github.com/christoomey/vim-tmux-navigator
-- Description: Enables seamless navigation between Neovim windows and tmux panes.

local util = require("plugins.util")

-- pre
vim.g.tmux_navigator_no_mappings = 1

-- install
vim.pack.add({ util.gh("christoomey/vim-tmux-navigator") })

-- keymaps
vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Move left" })
vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Move down" })
vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Move up" })
vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Move right" })
vim.keymap.set("t", "<C-h>", [[<C-\><C-n><cmd>TmuxNavigateLeft<cr>]], { desc = "Move left (terminal)" })
vim.keymap.set("t", "<C-j>", [[<C-\><C-n><cmd>TmuxNavigateDown<cr>]], { desc = "Move down (terminal)" })
vim.keymap.set("t", "<C-k>", [[<C-\><C-n><cmd>TmuxNavigateUp<cr>]], { desc = "Move up (terminal)" })
vim.keymap.set("t", "<C-l>", [[<C-\><C-n><cmd>TmuxNavigateRight<cr>]], { desc = "Move right (terminal)" })
