-- Plugins:
-- - nvim-ufo: https://github.com/kevinhwang91/nvim-ufo
--   Provides enhanced folding with providers like Treesitter and indent.
-- - promise-async: https://github.com/kevinhwang91/promise-async
--   Provides async primitives required by nvim-ufo.

local util = require("plugins.util")

local opts = {
    provider_selector = function(bufnr, filetype, buftype)
        return { "treesitter", "indent" }
    end,
}

-- install
vim.pack.add({
    util.gh("kevinhwang91/promise-async"),
    util.gh("kevinhwang91/nvim-ufo"),
})

-- setup
vim.o.foldcolumn = "0"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

vim.opt.fillchars:append({
    fold = " ",
    foldopen = " ",
    foldsep = " ",
    foldclose = " ",
})

local ufo = require("ufo")
ufo.setup(opts)

-- keymaps
vim.keymap.set("n", "zR", ufo.openAllFolds, { desc = "Open all folds" })
vim.keymap.set("n", "zM", ufo.closeAllFolds, { desc = "Close all folds" })
vim.keymap.set("n", "K", function()
    local winid = ufo.peekFoldedLinesUnderCursor()
    if not winid then
        vim.lsp.buf.hover()
    end
end, { desc = "Peek fold / LSP Hover" })
