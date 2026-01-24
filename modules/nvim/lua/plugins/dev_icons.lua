return {
  {
    "nvim-tree/nvim-web-devicons",
    lazy = false,
    config = function()
      require("nvim-web-devicons").setup({
        color_icons = false,
        default = true,
      })
    end,
  },
}
