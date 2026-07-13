-- Improved quickfix UI with context lines and editing
return {
    "stevearc/quicker.nvim",
    ft = "qf",
    opts = {},
    keys = {
        { "<leader>q", function() require("quicker").toggle() end, desc = "Toggle quickfix" },
        { "<leader>l", function() require("quicker").toggle({ loclist = true }) end, desc = "Toggle loclist" },
    },
}
