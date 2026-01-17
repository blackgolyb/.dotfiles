return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    lazy = false,
    opts = {
          window = {
            position = "right",
            width = 30,
          },
          filesystem = {
            follow_current_file = {
              enabled = true,
            },
            filtered_items = {
              hide_dotfiles = false,
              hide_gitignored = false,
            },
          },
        }
  }
}
