return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup()

      vim.keymap.set("n", "<leader>t", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, { desc = "Harpoon Menu" })

      vim.keymap.set("n", "<leader>a", function()
        harpoon:list():add()
      end, { desc = "Harpoon Add File" })

      vim.keymap.set("n", "<leader>d", function()
        harpoon:list():remove()
      end, { desc = "Harpoon Remove File" })

      vim.keymap.set("n", "<leader>C", function()
        require("harpoon"):list():clear()
      end, { desc = "Harpoon Clear List" })

      vim.keymap.set("n", "<M-f>", function() harpoon:list():select(1) end)
      vim.keymap.set("n", "<M-d>", function() harpoon:list():select(2) end)
      vim.keymap.set("n", "<M-s>", function() harpoon:list():select(3) end)
      vim.keymap.set("n", "<M-a>", function() harpoon:list():select(4) end)
    end,
  },
}
