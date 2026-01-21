return {
  "stevearc/aerial.nvim",
  dependencies = {
     "nvim-treesitter/nvim-treesitter",
     "nvim-tree/nvim-web-devicons"
  },
  config = function()
    require("aerial").setup({
      layout = {
        min_width = 30,
      },
      manage_folds = false,
    })

    require("telescope").load_extension("aerial")

    vim.keymap.set("n", "gs", "<cmd>Telescope aerial<CR>", { desc = "Search Symbols (Aerial)" })
  end,
}
