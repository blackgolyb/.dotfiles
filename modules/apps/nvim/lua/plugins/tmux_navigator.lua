return {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    init = function()
        vim.g.tmux_navigator_no_mappings = 1
    end,
    keys = {
        { "<C-h>", "<cmd>TmuxNavigateLeft<cr>",  desc = "Move left" },
        { "<C-j>", "<cmd>TmuxNavigateDown<cr>",  desc = "Move down" },
        { "<C-k>", "<cmd>TmuxNavigateUp<cr>",    desc = "Move up" },
        { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Move right" },
    },
}
