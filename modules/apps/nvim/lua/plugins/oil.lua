local ui = require("core.ui")

return {
  "stevearc/oil.nvim",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    {
      "<leader>E",
      "<cmd>Oil --float<cr>",
      desc = "Open oil at the current file",
    },
  },
  opts = {
    default_file_explorer = true,
    columns = {
      "icon",
    },
    keymaps = {
      -- ["<Esc>"] = "actions.close",
      ["q"] = "actions.close",
    },
    view_options = {
      show_hidden = true,
    },
    float = {
      border = ui.surface_border,
    },
    confirmation = {
      border = ui.surface_border,
    },
    progress = {
      border = ui.surface_border,
      minimized_border = ui.surface_border,
    },
    ssh = {
      border = ui.surface_border,
    },
    keymaps_help = {
      border = ui.surface_border,
    },
  },
  init = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end,
}
