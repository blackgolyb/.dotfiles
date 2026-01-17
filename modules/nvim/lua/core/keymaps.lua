vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Filetree
vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle Explorer", silent = true })

-- Statusbar
local status_visible = true
local function toggle_status_bar()
  if status_visible then
    vim.opt.laststatus = 0
  else
    vim.opt.laststatus = 3
  end
  status_visible = not status_visible
end
vim.keymap.set("n", "<leader>S", toggle_status_bar, { desc = "Toggle Statusline" })
