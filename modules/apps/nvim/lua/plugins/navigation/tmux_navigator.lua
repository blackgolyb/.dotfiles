-- Seamless tmux pane navigation
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
        { "<C-h>", [[<C-\><C-n><cmd>TmuxNavigateLeft<cr>]],  mode = "t", desc = "Move left (terminal)" },
        { "<C-j>", [[<C-\><C-n><cmd>TmuxNavigateDown<cr>]],  mode = "t", desc = "Move down (terminal)" },
        { "<C-k>", [[<C-\><C-n><cmd>TmuxNavigateUp<cr>]],    mode = "t", desc = "Move up (terminal)" },
        { "<C-l>", [[<C-\><C-n><cmd>TmuxNavigateRight<cr>]], mode = "t", desc = "Move right (terminal)" },
    },
}
