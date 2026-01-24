vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

vim.keymap.set("n", "Q", "<nop>")

-- При гортанні сторінок
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- При пошуку (наступне/попереднє співпадіння)
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste over selection" })

vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move to bottom window' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move to top window' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })


-- vim.keymap.set({"o", "x"}, "ie", ":<C-u>normal! ggVG<CR>", { silent = true, desc = "Text object for entire buffer" })

-- Statusbar
local function toggle_status_bar()
  vim.opt.laststatus = vim.opt.laststatus:get() > 0 and 0 or 3
end
vim.keymap.set("n", "<leader>s", toggle_status_bar, { desc = "Toggle Statusline" })


-- Commands
local cabbrev = function(expanded, original)
  vim.cmd('cnoreabbrev ' .. expanded .. ' ' .. original)
end

cabbrev('W', 'w')
cabbrev('Q', 'q')
cabbrev('Wq', 'wq')
cabbrev('WQ', 'wq')
cabbrev('Wa', 'wa')
cabbrev('Qa', 'qa')
