-- Plugin: molten-nvim
-- URL: https://github.com/benlubas/molten-nvim
-- Description: Interact with code cells in a Jupyter-like experience.

local util = require("plugins.util")

vim.pack.add({
    { src = util.gh("benlubas/molten-nvim"), version = "v1.9.2" },
})

vim.g.molten_image_provider = "image.nvim"
vim.g.molten_auto_open_output = false
vim.g.molten_output_win_max_height = 20
vim.g.molten_virt_text_output = true
vim.g.molten_wrap_output = true
vim.g.molten_use_border_highlights = true
vim.g.molten_virt_lines_off_by_1 = true
vim.g.molten_output_crop_border = true

vim.keymap.set("n", "<localleader>mi", ":MoltenInit<CR>", { desc = "Molten: Init kernel", silent = true })
vim.keymap.set(
    "n",
    "<localleader>me",
    ":MoltenEvaluateOperator<CR>",
    { desc = "Molten: Evaluate operator", silent = true }
)
vim.keymap.set("n", "<localleader>ml", ":MoltenEvaluateLine<CR>", { desc = "Molten: Evaluate line", silent = true })
vim.keymap.set(
    "n",
    "<localleader>rr",
    ":MoltenReevaluateCell<CR>",
    { desc = "Molten: Re-evaluate cell", silent = true }
)
vim.keymap.set(
    "v",
    "<localleader>r",
    ":<C-u>MoltenEvaluateVisual<CR>gv",
    { desc = "Molten: Evaluate visual", silent = true }
)
vim.keymap.set(
    "n",
    "<localleader>mo",
    ":noautocmd MoltenEnterOutput<CR>",
    { desc = "Molten: Open output", silent = true }
)
vim.keymap.set("n", "<localleader>mh", ":MoltenHideOutput<CR>", { desc = "Molten: Hide output", silent = true })
vim.keymap.set("n", "<localleader>md", ":MoltenDelete<CR>", { desc = "Molten: Delete cell", silent = true })
vim.keymap.set("n", "<localleader>mx", ":MoltenOpenInBrowser<CR>", { desc = "Molten: Open in browser", silent = true })

vim.keymap.set("n", "<localleader>mp", function()
    local venv = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX")
    if venv then
        venv = vim.fn.fnamemodify(venv, ":t")
        vim.cmd(("MoltenInit %s"):format(venv))
    else
        vim.cmd("MoltenInit python3")
    end
end, { desc = "Molten: Init kernel from venv", silent = true })
