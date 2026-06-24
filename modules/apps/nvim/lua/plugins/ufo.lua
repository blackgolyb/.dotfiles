return {
  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = "BufReadPost",
    opts = {
      provider_selector = function(bufnr, filetype, buftype)
        return { "treesitter", "indent" }
      end,
    },
    config = function(_, opts)
      vim.o.foldcolumn = '0'
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true

      vim.opt.fillchars:append({
        fold = " ",
        foldopen = " ",
        foldsep = " ",
        foldclose = " ",
      })

      local ufo = require('ufo')

      ufo.setup(opts)

      vim.keymap.set('n', 'zR', ufo.openAllFolds, { desc = "Open all folds" })
      vim.keymap.set('n', 'zM', ufo.closeAllFolds, { desc = "Close all folds" })
      vim.keymap.set('n', 'K', function()
        local winid = ufo.peekFoldedLinesUnderCursor()
        if not winid then
          vim.lsp.buf.hover()
        end
      end, { desc = "Peek fold / LSP Hover" })
    end,
  },
}
